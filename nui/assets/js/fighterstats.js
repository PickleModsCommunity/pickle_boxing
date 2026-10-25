function ShowFighterStats(data) {
    let format = `
        <div>
            <div style="background-image: url(${escapeBoxing(data.image)})"></div>
        </div>
        <div>
            <div>
                <div>${escapeBoxing(data.name.toUpperCase())}</div>
            </div>
            <div>
                <div>
                    <div>RECORD</div>
                    <div>${escapeBoxing(data.record.wins)} - ${escapeBoxing(data.record.losses)} - ${escapeBoxing(data.record.ties)}</div>
                </div>
                <div>
                    <div>AGE</div>
                    <div>${escapeBoxing(data.age)}</div>
                </div>
                <div>
                    <div>WEIGHT</div>
                    <div>${escapeBoxing(data.weight)} LBS</div>
                </div>
                <div>
                    <div>HEIGHT</div>
                    <div>${escapeBoxing(data.height)}</div>
                </div>
            </div>
        </div>
    `
    $("#fighterstats-container").html(format);
    $("#app-fighterstats").fadeIn(1000);
}

function HideFighterStats() {
    $("#app-fighterstats").fadeOut(1000, function() {
        $("#fighterstats-container").html("");
    });
}