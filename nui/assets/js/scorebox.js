fightState = {}

function ScoreboardTimer() {
    let time = fight.game.roundTime - 1;
    if (time <= 0) {
        fight.game.roundTime = 0;
        $("#scorebox-time").html(ConvertMinutes(fight.game.roundTime))
        return true;
    } 
    else {
        fight.game.roundTime = time;
        $("#scorebox-time").html(ConvertMinutes(fight.game.roundTime))
    }
}

function ShowScoreboard(data) {
    fight = data;
    let round = "R" + data.game.round
    let template = `
        <div>
            <div>
                <div>${escapeBoxing(fight.fighters[0].name)}</div>
            </div>
            <div class="as-scorebox">
                <div id="fighter-0-score" class="box red">${escapeBoxing(fight.fighters[0].hits)}</div>
                <img src="assets/images/logo.png"/>
                <div id="scorebox-time">${escapeBoxing(ConvertMinutes(fight.game.roundTime))}</div>
                <div>${escapeBoxing(round)}</div>
                <div id="fighter-1-score" class="box blue">${escapeBoxing(fight.fighters[1].hits)}</div>
            </div>
            <div>
                <div>${escapeBoxing(fight.fighters[1].name)}</div>
            </div>
        </div>
        <div>
            <div>${escapeBoxing(fight.settings.event.toUpperCase() || "MAIN EVENT")}</div>
        </div>
    `
    ResumeScoreboard(fight.game.roundTime);
    $("#scoreboard-container").html(template);
    $("#app-scoreboard").fadeIn(1000);
}

function HideScoreboard() {
    $("#app-scoreboard").fadeOut(1000, function() {
        $("#scoreboard-container").html("");
    });
}

function PauseScoreboard(seconds) {
    if (!fight) return;
    if (fightState.timeInterval) {
        clearInterval(fightState.timeInterval)
        fightState.timeInterval = null;
    }
    fight.game.roundTime = seconds;
    $("#scorebox-time").html(ConvertMinutes(fight.game.roundTime))
}

function ResumeScoreboard(seconds) {
    if (!fight) return;
    PauseScoreboard(seconds);
    fightState.timeInterval = setInterval(() => {
        let stop = ScoreboardTimer();
        if (stop) {
            clearInterval(fightState.timeInterval)
            fightState.timeInterval = null;
        }
    }, 1000);
    fight.game.roundTime = seconds;
    $("#scorebox-time").html(ConvertMinutes(fight.game.roundTime))
}

function UpdateScoreboard(data) {
    $("#fighter-0-score").html(data.fighters[0].hits);
    $("#fighter-1-score").html(data.fighters[1].hits);
}