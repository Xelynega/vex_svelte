<script>
import mqtt from "mqtt";

let arena_id;
/** @type {string} */
let arena_topic;
/** @type {string} */
let arena_state_topic;
/** @type {string} */
let arena_score_topic;

let event_name = "Mecha Mayhem 2024";
let match_name = "Qualification 1";
let score_red = 0;
let score_blue = 0;
let teams_red = ["6659A", "6659B"];
let teams_blue = ["210Z", "210Y"];
let timer_running = false;
let timer_start = undefined;
let timer_duration = undefined;
let timer = "Scheduled";

const client = mqtt.connect("ws://127.0.0.1:8883");

client.on("connect", () => {
  console.log("connected to mqtt");
  client.subscribe(arena_topic, (err) => {
    if (err) {
      console.log(err);
    } else {
      console.log(`subscribed to ${arena_topic}`);
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

client.on("message", (topic, message) => {
  let topic_str = topic.toString();
  let message_str = message.toString();

  console.log(`${topic_str} - ${message_str}`);

  switch(topic_str){
  case arena_topic:
    const arena_obj = JSON.parse(message_str);
    teams_red = [arena_obj.red1, arena_obj.red2];
    teams_blue = [arena_obj.blue1, arena_obj.blue2];
    // TODO: fill match name based off metadata
    break;
  case arena_state_topic:
    const state_obj = JSON.parse(message_str);
    // Convert seconds to ms *1000 convert ns to ms /1000000
    const start_time = new Date((state_obj.start_s * 1000) + (state_obj.start_ns / 1000000));
    switch(state_obj.state) {
    case "SCHEDULED":
      timer = "Scheduled";
      timer_running = false;
      break;
    case "TIMEOUT":
      timer = "Timeout";
      timer_running = false;
      break;
    case "DRIVER":
      timer_running = true;
      timer_start = start_time;
      timer_duration = 105000;
      break;
    case "DRIVER_DONE":
      timer = "Driver Done";
      timer_running = false;
      break;
    case "AUTONOMOUS":
      timer_running = true;
      timer_start = start_time;
      timer_duration = 15000;
      break;
    case "AUTONOMOUS_DONE":
      timer = "Auton Done";
      timer_running = false;
      break;
    case "ABANDONED":
      timer = "Abandoned";
      timer_running = false;
      break;
    }
    break;
  case arena_score_topic:
    const score_obj = JSON.parse(message_str);
    score_red = score_obj.red.total;
    score_blue = score_obj.blue.total;
    break;
  default:
    console.log(`Unhandled topic ${topic_str}`)
  }
});

import { onMount } from 'svelte';
onMount(() => {
  const search_params = new URLSearchParams(window.location.search);
  arena_id = search_params.get("arena");
  arena_topic = `arena/${arena_id}`;
  arena_state_topic = `arena/${arena_id}/state`;
  arena_score_topic = `arena/${arena_id}/score`;
});

</script>

<div class="center-display container" style="border: 1px solid black;">
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

.container {
  container-type: size;
}

div.score-grid {
  width: 100%;
  height: 100%;
  display: grid;

  justify-items: center;
  align-items: center;

  grid-template: 30% 40% 30% / 20% 40% 20%;

  grid-template-areas:
  "red-top top blue-top"
  "red-mid mid blue-mid"
  "red-bot bot blue-bot";
}

.side-display {
  background-color: transparent;
  width: 896px;
  height: 128px;
}

.center-display {
  background-color: transparent;
  width: 1176px;
  height: 168px;
}
</style>
