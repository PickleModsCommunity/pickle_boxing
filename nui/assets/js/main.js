function escapeBoxing(v) { return String(v ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c])); }
var fight = null;
var fightState = null;

function ZeroPad(num) {
    if (num < 10) {
        return "0" + num;
    }
    return num;
}

function ConvertMinutes(time) {
    const minutes = Math.floor(time / 60);
    const seconds = time - minutes * 60;
    if (minutes > 0) {
        return minutes + ":" + ZeroPad(seconds);
    }
    else {
        return ":" + ZeroPad(seconds);
    }
}

function Percent(num, max) {
    var pct = Math.ceil(100 * (num / max));
    if (pct < 0) {
        pct = 0;
    }
    else if (pct > 100) {
        pct = 100;
    }
    return pct;
}

window.addEventListener('message', function(ev) {
    if (ev.data.type == "knockoutStart") {
        KnockoutStart(ev.data.seconds, ev.data.recover);
    }
    else if (ev.data.type == "knockoutStop") {
        KnockoutStop();
    }
    else if (ev.data.type == "knockoutKeypress") {
        KnockoutKeypress();
    }
    else if (ev.data.type == "showStats") {
        ShowStats(ev.data.data);
    }
    else if (ev.data.type == "hideStats") {
        HideStats();
    }
    else if (ev.data.type == "showFighterStats") {
        ShowFighterStats(ev.data.data);
    }
    else if (ev.data.type == "hideFighterStats") {
        HideFighterStats();
    }
    else if (ev.data.type == "showScoreboard") {
        ShowScoreboard(ev.data.data);
    }
    else if (ev.data.type == "hideScoreboard") {
        HideScoreboard();
    }
    else if (ev.data.type == "resumeScoreboard") {
        ResumeScoreboard(ev.data.data);
    }
    else if (ev.data.type == "pauseScoreboard") {
        PauseScoreboard(ev.data.data);
    }
    else if (ev.data.type == "updateScoreboard") {
        UpdateScoreboard(ev.data.data)
    }
}) 
$(document).ready(function() {
})