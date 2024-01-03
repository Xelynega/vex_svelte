<script>
import mqtt from "mqtt";

let arena_id;
/** @type {string} */
let arena_metadata_topic;
/** @type {string} */
let arena_state_topic;
/** @type {string} */
let arena_score_topic;
/** @type {string} */
let display_state_topic;
/** @type {string} */
let display_class_topic;

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
/** @type {undefined | ReturnType<typeof setTimeout>} */
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

  client.subscribe(arena_metadata_topic, (err) => {
    if (err) {
      console.log(err);
    } else {
      console.log(`subscribed to ${arena_metadata_topic}`);
    }
  });

  client.subscribe(arena_state_topic, (err) => {
    if (err) {
      console.log(err);
    } else {
      console.log(`subscribed to ${arena_state_topic}`);
    }
  });

  client.subscribe(arena_score_topic, (err) => {
    if (err) {
      console.log(err);
    } else {
      console.log(`subscribed to ${arena_score_topic}`);
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
  case arena_metadata_topic:
    const arena_obj = JSON.parse(message_str);
    teams_red = [arena_obj.red1, arena_obj.red2];
    teams_blue = [arena_obj.blue1, arena_obj.blue2];
    // TODO: fill match name based off metadata
    break;
  case arena_state_topic:
    stop_timer();

    const state_obj = JSON.parse(message_str);
    // Convert seconds to ms *1000 convert ns to ms /1000000
    const start_ms = (state_obj.start_s * 1000) + (state_obj.start_ns / 1000000);
    switch(state_obj.state) {
    case "SCHEDULED":
      timer = "Scheduled";
      break;
    case "TIMEOUT":
      timer = "Timeout";
      break;
    case "DRIVER":
      timer_end = new Date(start_ms + 105000);
      tick_timer();
      timer_next_tick = setInterval(tick_timer, 50);
      break;
    case "DRIVER_DONE":
      timer = "Driver Done";
      break;
    case "AUTONOMOUS":
      timer_end = new Date(start_ms + 15000);
      tick_timer();
      timer_next_tick = setInterval(tick_timer, 50);
      break;
    case "AUTONOMOUS_DONE":
      timer = "Auton Done";
      break;
    case "ABANDONED":
      timer = "Abandoned";
      break;
    }
    break;
  case arena_score_topic:
    const score_obj = JSON.parse(message_str);
    score_red = score_obj.red.total;
    score_blue = score_obj.blue.total;
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
  default:
    console.log(`Unhandled topic ${topic_str}`)
  }
});

import { onMount } from 'svelte';
onMount(() => {
  const search_params = new URLSearchParams(window.location.search);
  arena_id = search_params.get("arena");
  if (arena_id === null) {
    arena_id = "default";
  }
  arena_metadata_topic = `arena/${arena_id}`;
  arena_state_topic    = `arena/${arena_id}/state`;
  arena_score_topic    = `arena/${arena_id}/score`;
  display_state_topic  = `display/${arena_id}/state`;
  display_class_topic  = `display/${arena_id}/class`;
});

</script>

<div class={display_class} style="border: 1px solid black;">
  {#if (display_state == "timer")}
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
  {:else if (display_state == "init")}
    <div class="banner"><p>{event_name}</p></div>
  {:else}
    <div class="banner"><p>Invalid State {display_state}</p></div>
  {/if}
</div>

<style>
:global(html){
  background-color: transparent;
}

:global(body){
  margin: 0;
  padding: 0;
  background-color: transparent;
}

p {
  margin: 0px;
  color: gray;
}

.banner {
  display: flex;
  font-size: 8cqw;
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
}

#score-blue {
  grid-area: blue-mid;

  font-size: 5cqw;
  justify-self: right;
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
  background-color: transparent;
  width: 896px;
  height: 128px;
}

.center-display {
  container-type: size;
  background-color: transparent;
  width: 1176px;
  height: 168px;
}
</style>
