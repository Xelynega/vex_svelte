<script>
import mqtt from "mqtt";

let field_id;
/** @type {string} */
let field_metadata_topic;
/** @type {string} */
let field_state_topic;
/** @type {string} */
let field_score_topic;
/** @type {string} */
let display_state_topic;
/** @type {string} */
let display_class_topic;
/** @type {string} */
let display_name_topic;

/** @type {string} */
let alliance_selecting = "";
/** @type {string} */
let alliance_selected = "";
let selection_state = "";

/** @type {string} */
let display_sponsor_topic;

/** @type {number} */
let score_midpoint_current = 50;
/** @type {number} */
let score_midpoint_setpoint = 50;

/** @type {string} */
let sponsor_state = "westmech";

let coeff_p = 0.1;
let final_hack = true;

let red_anim_x = 0;
let blue_anim_x = 0;
let offset = 0;

function animation_timer(){
  // Midpoint calculation
  let delta = score_midpoint_setpoint - score_midpoint_current;
  score_midpoint_current = score_midpoint_current + (delta * coeff_p);

  let current = Date.now() + offset;
  let x = (current % 1500) / 1500;
  let percent = -((x - 1)*(x - 1)) + 1;
  red_anim_x = score_midpoint_current * percent;
  blue_anim_x = (100 - score_midpoint_current) * percent;
}
let animation_timer_interval = setInterval(animation_timer, 10);

let event_name = "Mecha Mayhem 2024";
let match_name = "No Match";
let round = "";
let number = "";
let instance = "";
let score_red = 0;
let score_red_str = "";
let score_blue = 0;
let score_blue_str = "";
/** @type {string[]} */
let teams_red = [];
/** @type {string[]} */
let teams_blue = [];

/** @type {undefined | Number} */
let timer_end = undefined;
/** @type {undefined | ReturnType<typeof setInterval>} */
let timer_next_tick = undefined;
let timer = "Next Match";

/** @type {string} */
let display_state = "init";

/** @type {string} */
let display_name = "default";

/** @type {string} */
let display_class = "side-display";

const client = mqtt.connect("ws://10.42.0.36:8883");


client.on("connect", () => {
  console.log("connected to mqtt");

  client.subscribe("alliance/selecting", (err) => {
    if (err) {
      console.log(err);
    } else {
      console.log(`subscribed to alliance/selecting`);
    }
  });

  client.subscribe("alliance/selected", (err) => {
    if (err) {
      console.log(err);
    } else {
      console.log(`subscribed to alliance/selected`);
    }
  });

  client.subscribe("alliance/status", (err) => {
    if (err) {
      console.log(err);
    } else {
      console.log(`subscribed to alliance/status`);
    }
  });

  client.subscribe("time", (err) => {
    if (err) {
      console.log(err);
    } else {
      console.log(`subscribed to ${display_state_topic}`);
    }
  });

  client.subscribe(display_state_topic, (err) => {
    if (err) {
      console.log(err);
    } else {
      console.log(`subscribed to ${display_state_topic}`);
    }
  });

  client.subscribe(display_class_topic, (err) => {
    if (err) {
      console.log(err);
    } else {
      console.log(`subscribed to ${display_class_topic}`);
    }
  });

  client.subscribe(display_name_topic, (err) => {
    if (err) {
      console.log(err);
    } else {
      console.log(`subscribed to ${display_name_topic}`);
    }
  });

  client.subscribe(display_sponsor_topic, (err) => {
    if (err) {
      console.log(err);
    } else {
      console.log(`subscribed to ${display_sponsor_topic}`);
    }
  });

  client.subscribe(field_metadata_topic, (err) => {
    if (err) {
      console.log(err);
    } else {
      console.log(`subscribed to ${field_metadata_topic}`);
    }
  });

  client.subscribe(field_state_topic, (err) => {
    if (err) {
      console.log(err);
    } else {
      console.log(`subscribed to ${field_state_topic}`);
    }
  });

  client.subscribe(field_score_topic, (err) => {
    if (err) {
      console.log(err);
    } else {
      console.log(`subscribed to ${field_score_topic}`);
    }
  });
});

function stop_timer() {
  if(timer_next_tick === undefined) {
  } else {
    clearInterval(timer_next_tick);
    timer_next_tick = undefined;
  }
}

function tick_timer() {
  if(timer_end === undefined) {
    stop_timer();
    return

  }

  const now = new Date()
  const time_diff = (timer_end*1000) - now.getTime() - offset;
  console.log(`TIME_DIFF: ${time_diff} = ${timer_end} - ${now.getTime()} - ${offset}`);
  if (time_diff <= 0) {
    timer = "0:00";
    stop_timer();
  } else {
    const seconds_total = Math.ceil(time_diff/ 1000);
    const minutes = Math.floor(seconds_total / 60);
    const seconds = seconds_total - (minutes * 60);
    timer = `${minutes}:${seconds.toString().padStart(2, '0')}`;
  }
}

client.on("message", (topic, message) => {
  let topic_str = topic.toString();
  let message_str = message.toString();

  if (topic_str == "alliance/selecting") {
    alliance_selecting = message_str;
  } else if (topic_str == "alliance/selected") {
    alliance_selected = message_str;
  } else if (topic_str == "alliance/status") {
    selection_state = message_str;
    if(selection_state == "accepted") {
      display_state = "accepted";
      setTimeout(() => {
        display_state = "alliance-selection";
      }, 4000);
    } else if(selection_state == "declined") {
      display_state = "denied";
      setTimeout(() => {
        display_state = "alliance-selection";
      }, 4000);
    }
  } else if (topic_str == "time") {
    let local = Date.now();
    let server = JSON.parse(message_str) * 1000;
    offset = server - local;

    if (timer != "Scoring" && timer != "Scored") {
      stop_timer();
      tick_timer();
      timer_next_tick = setInterval(tick_timer, 50);
    }

    console.log(`NEW_OFFSET: ${server} - ${local} = ${offset}`);
  } else if (topic_str.match(/^field\/[^\/]+\/[^\/]+$/)) {
    const field_obj = JSON.parse(message_str);
    teams_red = [field_obj.red_teams[0], field_obj.red_teams[1]];
    teams_blue = [field_obj.blue_teams[0], field_obj.blue_teams[1]];
    let num = field_obj.tuple.match_num;
    round = field_obj.tuple.round;
    if (round == "Qualification") {
      round = "Qual";
    } else if (round == "QuarterFinals") {
      round = "QF"
    } else if (round == "SemiFinals") {
      round = "SF"
    }
    instance = `${field_obj.tuple.instance}`;
    match_name = `${round} ${instance}-${num}`;
    number = `${num}`;
  } else if (topic_str.match(/^field\/[^\/]+\/[^\/]+\/state$/)) {
    stop_timer();

    const state_obj = JSON.parse(message_str);
    const start_ms = state_obj.start;
    switch(state_obj.state) {
    case "Scheduled":
      timer = match_name;
      score_red_str = "";
      score_blue_str = "";
      score_blue = 0;
      score_red = 0;
      display_state = "pre-game";
      break;
    case "Timeout":
      timer = "Timeout";
      break;
    case "Driver":
      timer_end = start_ms + 105;
      tick_timer();
      timer_next_tick = setInterval(tick_timer, 50);
      break;
    case "DriverDone":
      timer = "Scoring";
      score_red_str = "";
      score_blue_str = "";
      display_state = sponsor_state;
      setTimeout(() => {
        display_state = "timer";
      }, 6000);
      break;
    case "Autonomous":
      if(display_state == "pre-game") {
        display_state = "timer";
      }
      score_red = 0;
      score_blue = 0;
      score_red_str = "0";
      score_blue_str = "0";

      timer_end = start_ms + 15;
      tick_timer();
      timer_next_tick = setInterval(tick_timer, 50);
      break;
    case "AutonomousDone":
      timer = "Scoring";
      score_red_str = "";
      score_blue_str = "";
      break;
    case "Abandoned":
      timer = "Abandoned";
      break;
    case "Stopped":
      timer = "Stopped";
      break;
    case "Scored":
      timer = "Scored";
      score_red_str = `${score_red}`;
      score_blue_str = `${score_blue}`;
      display_state = "timer";
      break;
    }
  } else if (topic_str.match(/^field\/[^\/]+\/[^\/]+\/score$/)) {
    const score_obj = JSON.parse(message_str);
    score_red = score_obj.red_total;
    score_blue = score_obj.blue_total;
    if (timer != "Scoring") {
      score_red_str = `${score_red}`;
      score_blue_str = `${score_blue}`;
    }
    score_midpoint_setpoint = ((score_red + 1) / (score_red + score_blue + 2)) * 100;
  } else if (topic_str == display_state_topic) {
    display_state = message_str;
  } else if (topic_str == display_sponsor_topic) {
    sponsor_state = message_str;
  } else if (topic_str == display_name_topic) {
    display_name = message_str;
  } else if (topic_str == display_class_topic) {
    switch(message_str){
    case "side":
      display_class = "side-display";
      break;
    case "center":
      display_class = "center-display";
      break;
    default:
      console.log(`invalid display class ${message_str}`)
    }
  } else {
    console.log(`Unhandled topic ${topic_str}`)
  }
});

import { onMount } from 'svelte';
onMount(() => {
  const search_params = new URLSearchParams(window.location.search);
  field_id = search_params.get("field");
  if (field_id === null) {
    field_id = "default";
  }
  display_state_topic  = `display/${field_id}/state`;
  display_class_topic  = `display/${field_id}/class`;
  display_name_topic   = `display/${field_id}/name`;
  display_sponsor_topic   = `display/${field_id}/sponsor`;
  // Hack for grand finals to show information on multiple fields
  if (final_hack && (field_id == "1/2" || field_id == "2/4")) {
    field_metadata_topic = `field/+/+`;
    field_state_topic    = `field/+/+/state`;
    field_score_topic    = `field/+/+/score`;
  } else {
    field_metadata_topic = `field/${field_id}`;
    field_state_topic    = `field/${field_id}/state`;
    field_score_topic    = `field/${field_id}/score`;
  }
});

</script>

<div class={display_class}>
  {#if (display_state == "init")}
    <div class="banner"></div>
  {:else if (display_state == "timer")}
    <div class="score-grid">
      <!-- <p id="event-name">{event_name}</p> -->
      <p id="red-name">{event_name}</p>
      <p id="blue-name">{display_name}</p>
      <p id="timer">{timer}</p>
      <p id="match">{match_name}</p>

      <p id="score-red">{score_red_str}</p>
      <p id="score-blue">{score_blue_str}</p>

      <div class="teams" id="teams-red">
        {#each teams_red as team}
          <p>{team}</p>
        {/each}
      </div>
      <div class="teams" id="teams-blue">
        {#each teams_blue as team}
          <p>{team}</p>
        {/each}
      </div>
    </div>
    <div id="score-midground">
    </div>
    <div id="score-background">
      <div id="score-background-red-1" style={`width: ${red_anim_x}%`}>
      </div>
      <div id="score-background-red-2" style={`width: ${score_midpoint_current - red_anim_x}%`}>
      </div>
      <div id="score-background-blue-1" style={`width: ${100 - score_midpoint_current - blue_anim_x}%`}>
      </div>
      <div id="score-background-blue-2" style={`width: ${blue_anim_x}%`}>
      </div>
    </div>
  {:else if (display_state == "pre-game")}
    <img class="gif-background" alt="wavy" src="/gifs/wavy_background.gif">
    <div class="pre-game">
      <div class="pre-bot" id="pre-r1">
        <p>{teams_red[0]}</p>
	<object type="image/png" data="/robots/{teams_red[0]}.gif">
          <img class="rotating" src="/robots/fallback.jpg">
	</object>
      </div>
      <div class="pre-bot" id="pre-r2">
        <p>{teams_red[1]}</p>
	<object type="image/png" data="/robots/{teams_red[1]}.gif">
          <img class="rotating" src="/robots/fallback.jpg">
	</object>
      </div>
      <div id="pre-mid">
        <p id="pre-mid-top">{round}</p>
        <div id="pre-mid-vs"><p>VS</p></div>
        <p id="pre-mid-bot">{instance}-{number}</p>
      </div>
      <div class="pre-bot" id="pre-b1">
        <p>{teams_blue[0]}</p>
	<object type="image/png" data="/robots/{teams_blue[0]}.gif">
          <img class="rotating" src="/robots/fallback.jpg">
	</object>
      </div>
      <div class="pre-bot" id="pre-b2">
        <p>{teams_blue[1]}</p>
        <object type="image/png" data="/robots/{teams_blue[1]}.gif">
          <img class="rotating" src="/robots/fallback.jpg">
	</object>
      </div>
    </div>
  {:else if (display_state == "event-name")}
    <img class="gif-background" alt="wavy" src="/gifs/wavy_background.gif">
    <img class="gif-foreground" alt="Mecha Mayhem 2024" src="/gifs/mm2024.gif">
  {:else if (display_state == "alliance-selection")}
    <img class="gif-background" alt="wavy" src="/gifs/wavy_background.gif">
    <div id="alliance-selection">
      <div class="select-top" id="t1"><p>Captain</p></div>
      <div class="select-top" id="t2"><p>Selected</p></div>
      <div id="alliance-selecting">
        {#if (alliance_selecting != "")}
	<object type="image/png" data="/robots/{alliance_selecting}.gif">
          <img class="rotating" src="/robots/fallback.jpg">
	</object>
        {/if}
        <p>{alliance_selecting}</p>
      </div>
      <div id="alliance-selected">
        {#if (alliance_selected != "")}
	<object type="image/png" data="/robots/{alliance_selected}.gif">
          <img class="rotating" src="/robots/fallback.jpg">
	</object>
        {/if}
        <p>{alliance_selected}</p>
      </div>
    </div>
  {:else if (display_state == "break")}
    <div class="banner"><p>Practice @ 12:45</p></div>
  {:else if (display_state == "red-wins")}
    <img class="gif-background" alt="wavy" src="/gifs/wavy_background.gif">
    <img class="gif-foreground" alt="red-wins" src="/gifs/red_win.gif">
  {:else if (display_state == "accepted")}
    <img class="gif-background" alt="wavy" src="/gifs/wavy_background.gif">
    <img class="gif-foreground" alt="accepted" src="/gifs/accepted.gif">
  {:else if (display_state == "denied")}
    <img class="gif-background" alt="wavy" src="/gifs/wavy_background.gif">
    <img class="gif-foreground" alt="denied" src="/gifs/declined.gif">
  {:else if (display_state == "blue-wins")}
    <img class="gif-background" alt="wavy" src="/gifs/wavy_background.gif">
    <img class="gif-foreground" alt="blue-wins" src="/gifs/blue_win.gif">
  {:else if (display_state == "rockies")}
    <img class="gif" alt="rockies" src="/gifs/rockies.gif">
  {:else if (display_state == "prairies")}
    <img class="gif" alt="prairies" src="/gifs/prairies.gif">
  {:else if (display_state == "ab-education")}
    <img class="gif-background" alt="wavy" src="/gifs/wavy_background.gif">
    <img class="gif-foreground" alt="ab-education" src="/gifs/ab_education.gif">
  {:else if (display_state == "ab-innovate")}
    <img class="gif-background" alt="wavy" src="/gifs/wavy_background.gif">
    <img class="gif-foreground" alt="ab-innovate" src="/gifs/ab_innovate.gif">
  {:else if (display_state == "tcenergy")}
    <img class="gif-background" alt="wavy" src="/gifs/wavy_background.gif">
    <img class="gif-foreground" alt="tcenergy" src="/gifs/tcenergy.gif">
  {:else if (display_state == "tourismcalgary")}
    <img class="gif-background" alt="wavy" src="/gifs/wavy_background.gif">
    <img class="gif-foreground" alt="tourismcalgary" src="/gifs/tourismcalgary.gif">
  {:else if (display_state == "encore")}
    <img class="gif-background" alt="wavy" src="/gifs/wavy_background.gif">
    <img class="gif-foreground" alt="encore" src="/gifs/encore.gif">
  {:else if (display_state == "westmech")}
    <img class="gif-background" alt="wavy" src="/gifs/wavy_background.gif">
    <img class="gif-foreground" alt="westmech" src="/gifs/westmech.gif">
  {:else}
    <div class="banner"><p>Invalid State {display_state}</p></div>
  {/if}
</div>

<style>
@font-face {
  font-family: "apple2";
  src: url('/fonts/apple2.woff2') format('woff2');
}

:global(html){
  background-color: pink;
}

:global(body){
  margin: 0;
  padding: 0;
}

p {
  font-family: "apple2";
  margin: 0px;
  color: white;
}

#alliance-selection {
  position: absolute;
  top: 0;
  z-index: 1;

  width: 100%;
  height: 100%;

  display: grid;

  grid-template-columns: 50% 50%;
  grid-template-rows: 10% 90%;
  grid-template-areas: "t1 t2"
                       "s1 s2";
}

#alliance-selecting {
  grid-area: s1;
  height: 100%;
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-direction: row-reverse;
  flex-grow: 0;
}

#alliance-selecting p {
  font-size: 3cqw;
}

#alliance-selected p {
  font-size: 3cqw;
}

#alliance-selected {
  grid-area: s2;
  height: 100%;
  width: 100%;
  display: flex;
  justify-content: center;
  align-items: center;
  flex-direction: row;
  flex-grow: 0;
}

#score-midground {
  z-index: 1;
  position: relative;
  top: -94%;
  left: 1%;
  height: 88%;
  width: 98%;
  background-color: black;
  background-image: url("/gifs/wavy_background.gif");
}

.gif-foreground {
  z-index: 1;
  position: absolute;
  top: 0;
  height: 100%;
  width: 100%;
}

.gif {
  width: 100%;
  height: 100%;
}

#pre-mid-vs {
  height: 60%;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  font-size: 3cqw;
}

#pre-mid-top {
  height: 20%;
  font-size: 2cqw;
}

#pre-mid-bot {
  height: 20%;
  font-size: 2cqw;
}

#pre-mid {
  text-wrap: nowrap;
  font-size: 7cqw;
  grid-area: mid;

  display: flex;
  flex-direction: column;
  justify-content: flex-start;
  align-items: center;
  flex-grow: 0;
  flex-basis: min-content;
  height: 100%;
  width: 100%;
}

.pre-bot object {
  height: 80cqh;
  width: 80cqh;
}

.pre-bot object img {
  height: 100%;
  width: 100%;
}

.pre-bot {
  display: flex;
  flex-direction: column;
  justify-content: flex-start;
  align-items: center;
  flex-grow: 0;
  flex-basis: min-content;
  height: 100%;
  width: 100%;
}

.select-top p {
  font-size: 1cqw;
}

.select-top {
  display: flex;
  justify-content: center;
  align-items: center;
}

#t1 {
  grid-area: t1;
}

#t2 {
  grid-area: t2;
}

#pre-b1 {
  font-size: 2cqw;
  grid-area: b1;
}

#pre-b2 {
  font-size: 2cqw;
  grid-area: b2;
}

#pre-r1 {
  font-size: 2cqw;
  grid-area: r1;
}

#pre-r2 {
  font-size: 2cqw;
  grid-area: r2;
}

.pre-game {
  z-index: 1;
  position: absolute;
  top: 0;
  height: 100%;
  width: 100%;

  display: grid;
  justify-items: center;
  align-items: center;
  grid-template-columns: 22.5% 22.5% 10% 22.5% 22.5%;
  grid-template-rows: 100%;
  grid-template-areas: "r1 r2 mid b1 b2";
}

.gif-background {
  z-index: 0;
  position: absolute;
  top: 0;
  height: 100%;
  width: 100%;
}

#score-background {
  z-index: 0;
  position: relative;
  top: -188%;
  display: flex;
  flex-direction: row;
  height: 100%;
}

#score-background-blue-1 {
  height: 100%;
  background-color: #0000ee;
}

#score-background-blue-2 {
  height: 100%;
  background-color: blue;
}

#score-background-red-1 {
  height: 100%;
  background-color: red;
}

#score-background-red-2 {
  height: 100%;
  background-color: #ee0000;
}

#alliance-selection div object img {
  height: 40cqh;
  width: 40cqh;
}

#alliance-selection div object {
  height: 180cqh;
  width: 180cqh;
  display: flex;
  align-items: center;
  justify-content: center;
}

.banner-gif {
  z-index: 0;
  position: absolute;
  top: 0;
  height: 100%;
  width: 100%;
}

.banner {
  z-index: 1;
  position: absolute;
  top: 0;
  display: flex;
  font-size: 5cqw;
  align-items: center;
  justify-content: space-evenly;

  height: 100%;
  width: 100%;
}

.teams {
  width: 125%;
  height: 100%;
  font-size: 2cqw;
  display: flex;
  justify-content: space-around;
  align-items: center;
}

#teams-red {
  flex-direction: row;
  grid-area: red-bot;
  margin-left: 50px;
}

#teams-blue {
  flex-direction: row-reverse;
  grid-area: blue-bot;
  margin-right: 50px;
}

#score-red {
  grid-area: red-mid;

  font-size: 5cqw;
  justify-self: left;
  padding-left: 2cqw;
}

#score-blue {
  grid-area: blue-mid;

  font-size: 5cqw;
  justify-self: right;
  padding-right: 2cqw;
}

#match {
  grid-area: bot;
  font-size: 2cqw;
}

#event-name {
  grid-area: top;
  font-size: 2cqw;
}

#blue-name {
  grid-area: blue-top;
  font-size: 1.5cqw;
  margin-right: 15px;
  margin-top: 10px;
  text-align: right;
}

#red-name {
  grid-area: red-top;
  font-size: 1.5cqw;
  margin-left: 15px;
  margin-top: 10px;
}

#timer {
  grid-area: mid;
  font-size: 5cqw;
}

div.score-grid {
  position: relative;
  background-color: transparent;
  z-index: 2;
  width: 100%;
  height: 100%;
  display: grid;

  justify-items: center;
  align-items: center;

  grid-template: 30% 40% 30% / 20% 60% 20%;

  grid-template-areas:
  "red-top top blue-top"
  "red-mid mid blue-mid"
  "red-bot bot blue-bot";
}

.side-display {
  container-type: size;
  background-color: white;
  width: 896px;
  height: 128px;
}

.center-display {
  container-type: size;
  background-color: white;
  width: 1176px;
  height: 168px;
}

@-webkit-keyframes rotating {
    from{
        -webkit-transform: rotate(0deg);
    }
    to{
        -webkit-transform: rotate(360deg);
    }
}

.rotating {
    -webkit-animation: rotating 2s linear infinite;
}
</style>
