pragma ComponentBehavior: Bound

import QtQuick
import Yoke.Interface

// One stream of a unit, joined to the present without a gap: it opens the delivery, starts the stream, and
// only then asks the question that states the present with its sequence; frames arriving meanwhile are
// held, and those at or below that sequence dropped. Every value it lets through, the present first, is
// handed to `value`, in the order the unit counted them. On every attachment, the first or one after the
// Core came back, it joins again.
//
// A stream whose values carry no sequence is not joined: each frame is handed on as it comes.
//
//   StreamJoin { unit: "power"; stream: "power.status"; onValue: v => … }
Item {
    id: join

    required property string unit
    required property string stream
    // The question that states the present; by default the stream's own name.
    property string question: stream
    property string payload: "{}"
    // While false the stream is stopped and nothing is asked: a stream the shell shows only in a panel
    // flows only while the panel is open.
    property bool wanted: true

    readonly property bool joined: _held === null
    property string error: ""

    signal value(var v)

    property var _held: []
    property var _at: undefined
    property bool _joining: false

    function _join(): void {
        if (_joining || !wanted || !Yoke.attached || !delivery.open)
            return;
        _joining = true;
        _held = [];
        _at = undefined;
        Yoke.link.startStream(unit, stream, null, refusal => {
            error = unit + " did not start " + stream + ": " + refusal.code;
        });
        Yoke.link.ask(unit, question, payload, answer => {
            const present = Yoke.json(answer);
            if (!present)
                return;
            error = "";
            const held = _held;
            _held = null;
            _apply(present);
            for (const v of held)
                _apply(v);
        }, refusal => {
            error = unit + " refused " + question + ": " + refusal.code;
            _joining = false;
        });
    }

    function _apply(v: var): void {
        if (v.sequence !== undefined) {
            if (_at !== undefined && v.sequence <= _at)
                return;
            _at = v.sequence;
        }
        join.value(v);
    }

    onWantedChanged: {
        if (wanted) {
            _joining = false;
            _join();
        } else {
            _joining = false;
            _held = [];
            Yoke.link.stopStream(unit, stream);
        }
    }

    Connections {
        target: Yoke
        function onAttachedChanged(): void {
            join._joining = false;
            join._join();
        }
    }

    Delivery {
        id: delivery

        attachment: Yoke.link
        unit: join.unit
        stream: join.stream
        onOpenChanged: join._join()
        onFrame: frame => {
            const v = Yoke.json(frame.payload);
            if (!v)
                return;
            if (join._held !== null)
                join._held.push(v);
            else
                join._apply(v);
        }
    }
}
