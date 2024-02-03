<script>
import mqtt from "mqtt";

let div_id;


/** @type {string[]} */

let red_teams = [];
let blue_teams = [];
let field_matches = [];


let latest_start_time = 0;
let active_field = 0;
let offset = 0;


let event_name = "Mecha Mayhem 2024";
let match_name = "No Match";
let match_name_show = "No Match";
/** @type {string[]} */
let teams_red = [];
/** @type {string[]} */
let teams_blue = [];

/** @type {undefined | Date} */
let timer_end = undefined;
/** @type {undefined | ReturnType<typeof setInterval>} */
let timer_next_tick = undefined;
let timer = "Next Match";

/** @type {string} */
let display_state = "init";

/** @type {string} */
let display_class = "side-display";

const client = mqtt.connect("ws://metznet.ca:8883");

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
  const time_diff = timer_end.getTime() - now.getTime() + offset;
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
  /** @type {RegExp} */
  let field_metadata_topic = /^field\/\d+\/(\d+)$/;
  /** @type {RegExp} */
  let field_state_topic = /^field\/\d+\/(\d+)\/state$/;

  let topic_str = topic.toString();
  let message_str = message.toString();
  let field_state_match = field_state_topic.exec(topic_str);
  let field_metadata_match = field_metadata_topic.exec(topic_str);

  console.log(`${topic_str} - ${message_str}`);
  
  if (field_state_match) {
    console.log("here")
    let [_, field] = field_state_match;
    const state_obj = JSON.parse(message_str);
    if (state_obj.state != "Scheduled") { return; }
    if (state_obj.start <= latest_start_time) { return; }

    latest_start_time = parseFloat(state_obj.start);
    active_field = parseInt(field);
    console.log(`${latest_start_time}`);
    console.log(`active field: ${active_field}`);

    let field_obj = field_matches[active_field];
    red_teams = [field_obj.red_teams[0], field_obj.red_teams[1]];
    blue_teams = [field_obj.blue_teams[0], field_obj.blue_teams[1]];
  }
  else if (field_metadata_match) {
    let [_, field] = field_metadata_match;
    const field_obj = JSON.parse(message_str);
    
    field_matches[parseInt(field)] = field_obj;
    if(field == active_field) {
      red_teams = [field_obj.red_teams[0], field_obj.red_teams[1]];
      blue_teams = [field_obj.blue_teams[0], field_obj.blue_teams[1]];
    }
  }
  else {
    console.log(`${topic_str} not defined`);
  }


  // switch(topic_str){
  // case "time":
  //   let local = Date.now();
  //   let server = JSON.parse(message_str) * 1000;
  //   offset = local - server;
  //   console.log(`NEW offset: ${local} - ${server} = ${offset}`);
  //   break;
  // case field_metadata_topic:
  //   const field_obj = JSON.parse(message_str);
  //   teams_red = [field_obj.red_teams[0], field_obj.red_teams[1]];
  //   teams_blue = [field_obj.blue_teams[0], field_obj.blue_teams[1]];
  //   let num = field_obj.tuple.match_num;
  //   let round = field_obj.tuple.round;
  //   match_name = `${round} ${num}`;
  //   break;
  // case field_state_topic:
  //   stop_timer();

  //   const state_obj = JSON.parse(message_str);
  //   const start_ms = state_obj.start * 1000;
  //   console.log(`Start_ms: ${start_ms}`);
  //   switch(state_obj.state) {
  //   case "Scheduled":
  //     timer = match_name;
  //     match_name_show = "Next Match";
  //     if (state_obj.start > latest_start_time) {
  //       latest_start_time = state_obj.start;
  //       active_field = parseFloat(topic_str.split("/")[2]);
  //       console.log(`${latest_start_time}`);
  //       console.log(`${active_field}`);
  //     }
  //     break;
  //   }
  //   break;
  // default:
  //   console.log(`Unhandled topic ${topic_str}`)
  // }
});

import { onMount } from 'svelte';
onMount(() => {
  const search_params = new URLSearchParams(window.location.search);
  div_id = search_params.get("division");
  if (div_id === null) {
    div_id = "default";
  }
  // field_metadata_topic = `field/${div_id}/+`;
  // field_state_topic    = `field/${div_id}/+/state`;

  client.on("connect", () => {
  console.log("connected to mqtt");

  client.subscribe(`field/${div_id}/#`, (err) => {
    if (err) {
      console.log("failed to subscribe to field metadata")
      console.log(err);
    } else {
      console.log(`subscribed`);
    }
  });
});
  
});

</script>

<div class="img-grid">
  {#each Object.entries(red_teams) as [index, team]}
    <div class="item">
      <video autoplay loop muted playsinline src="./{team}.mp4" alt="video {team}"></video>
      <div class="text">{team}</div>
    </div>
  {/each}
  {#each Object.entries(blue_teams) as [index, team]}
    <div class="item">
      <video autoplay loop muted playsinline src="./{team}.mp4" alt="video {team}"></video>
      <div class="text">{team}</div>
    </div>
  {/each}
</div>

<style>
  @import url('https://fonts.googleapis.com/css2?family=Bebas+Neue&display=swap');  

  .img-grid {
    display: grid;
    grid-template-columns: repeat(2, lfr);
    grid-template-rows: repeat(2, lfr);
    gap: 20px;
    width: 1920px;
    height: 1080px;
    justify-content: center;
    align-content: center;
    margin: auto;
    background-color: #2ae400;
    font-family: 'Bebas Neue';
    font-weight: 400;
  }

  .item {
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
  }

  img {
    width: 100%;
    height: auto;
  }

  .text {
    margin-top: 10px;
  }
</style>