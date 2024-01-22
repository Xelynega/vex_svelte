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

/** @type {number} */
let score_midpoint_current = 50;
/** @type {number} */
let score_midpoint_setpoint = 50;

let coeff_p = 0.1;

function midpoint_timer(){
  // start with simple P control, maybe add ID later
  let delta = score_midpoint_setpoint - score_midpoint_current;
  score_midpoint_current = score_midpoint_current + (delta * coeff_p);
}
let midpoint_timer_interval = setInterval(midpoint_timer, 10);

let event_name = "Mecha Mayhem 2024";
let match_name = "No Match";
let score_red = 0;
let score_blue = 0;
/** @type {string[]} */
let teams_red = [];
/** @type {string[]} */
let teams_blue = [];

/** @type {undefined | Date} */
let timer_end = undefined;
/** @type {undefined | ReturnType<typeof setInterval>} */
let timer_next_tick = undefined;
let timer = "Scheduled";

/** @type {string} */
let display_state = "init";

/** @type {string} */
let display_class = "side-display";

const client = mqtt.connect("ws://127.0.0.1:8883");

client.on("connect", () => {
  console.log("connected to mqtt");
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
  const time_diff = timer_end.getTime() - now.getTime();
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

  console.log(`${topic_str} - ${message_str}`);

  switch(topic_str){
  case field_metadata_topic:
    const field_obj = JSON.parse(message_str);
    teams_red = [field_obj.red_teams[0], field_obj.red_teams[1]];
    teams_blue = [field_obj.blue_teams[1], field_obj.blue_teams[1]];
    let num = field_obj.tuple.match_num;
    let round = field_obj.tuple.round;
    match_name = `${round} ${num}`;
    break;
  case field_state_topic:
    stop_timer();

    const state_obj = JSON.parse(message_str);
    const start_ms = state_obj.start * 1000;
    console.log(`Start_ms: ${start_ms}`);
    switch(state_obj.state) {
    case "Scheduled":
      timer = "Scheduled";
      break;
    case "Timeout":
      timer = "Timeout";
      break;
    case "Driver":
      timer_end = new Date(start_ms + 105000);
      tick_timer();
      timer_next_tick = setInterval(tick_timer, 50);
      break;
    case "DriverDone":
      timer = "00:00";
      break;
    case "Autonomous":
      timer_end = new Date(start_ms + 15000);
      tick_timer();
      timer_next_tick = setInterval(tick_timer, 50);
      break;
    case "AutonomousDone":
      timer = "00:00";
      break;
    case "Abandoned":
      timer = "Abandoned";
      break;
    case "Stopped":
      timer = "Stopped";
      break;
    case "Scored":
      timer = "Scoring";
      break;
    }
    break;
  case field_score_topic:
    const score_obj = JSON.parse(message_str);
    score_red = score_obj.red_total;
    score_blue = score_obj.blue_total;
    score_midpoint_setpoint = ((score_red + 1) / (score_red + score_blue + 2)) * 100;
    break;
  case display_state_topic:
    display_state = message_str;
    break;
  case display_class_topic:
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
    break;
  default:
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
  field_metadata_topic = `field/${field_id}`;
  field_state_topic    = `field/${field_id}/state`;
  field_score_topic    = `field/${field_id}/score`;
  display_state_topic  = `display/${field_id}/state`;
  display_class_topic  = `display/${field_id}/class`;
});

</script>

<div class={display_class}>
  {#if (display_state == "init")}
    <div class="banner"></div>
  {:else if (display_state == "timer")}
    <div class="score-grid">
      <p id="event-name">{event_name}</p>
      <p id="timer">{timer}</p>
      <p id="match">{match_name}</p>

      <p id="score-red">{score_red}</p>
      <p id="score-blue">{score_blue}</p>

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
    <div id="score-background">
      <div id="score-background-red" style={`width: ${score_midpoint_current}%`}>
      </div>
      <div id="score-background-blue" style={`width: ${100 - score_midpoint_current}%`}>
      </div>
    </div>
  {:else if (display_state == "pre-game")}
    <div id="pre-game"></div>
  {:else if (display_state == "event-name")}
    <div class="banner"><p>{event_name}</p></div>
  {:else if (display_state == "alliance-selection")}
    <div class="banner"><p>210Y Selecting</p></div>
  {:else if (display_state == "break")}
    <div class="banner"><p>Practice @ 12:45</p></div>
  {:else}
    <div class="banner"><p>Invalid State {display_state}</p></div>
  {/if}
</div>

<style>
@font-face {
  font-family: "apple2";
  src: url('/static/fonts/apple2.woff2') format('woff2');
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
  -webkit-text-stroke: 0.02em black;
}

#score-background {
  z-index: 0;
  position: relative;
  top: -100%;
  display: flex;
  flex-direction: row;
  height: 100%;
}

#score-background-blue {
  height: 100%;
  background-color: blue;
}

#score-background-red {
  height: 100%;
  background-color: red;
}

.banner {
  display: flex;
  font-size: 5cqw;
  align-items: center;
  justify-content: space-evenly;

  height: 100%;
  width: 100%;
}

.teams {
  width: 100%;
  height: 100%;
  font-size: 1.5cqw;
  display: flex;
  justify-content: space-around;
  align-items: center;
}

#teams-red {
  flex-direction: row;
  grid-area: red-bot;
}

#teams-blue {
  flex-direction: row-reverse;
  grid-area: blue-bot;
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

#timer {
  grid-area: mid;
  font-size: 5cqw;
}

div.score-grid {
  position: relative;
  background-color: transparent;
  z-index: 1;
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
</style>
