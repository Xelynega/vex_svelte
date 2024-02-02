<script>
import mqtt from "mqtt";

const client = mqtt.connect("ws://10.42.0.36:8883");

/**
* @type any
**/
let displays = new Object();

let states = ["init", "timer", "pre-game", "event-name", "alliance-selection", "break", "red-wins", "blue-wins", "prairies", "rockies", "ab-education", "ab-innovate", "tcenergy", "tourismcalgary", "westmech"];
let classes = ["center", "side"];

client.on("connect", () => {
  console.log("connected to mqtt");
  client.subscribe("display/+/+/class", (err) => {
    if (err) {
      console.log(err);
    } else {
      console.log("subscribed to display class topic");
    }
  });
  client.subscribe("display/+/+/state", (err) => {
    if (err) {
      console.log(err);
    } else {
      console.log("subscribed to display state topic");
    }
  });
});

client.on("message", (topic, message) => {
  let topic_str = topic.toString();
  let message_str = message.toString();
  let topic_parts = topic_str.split("/");
  let display_name = `${topic_parts[1]}/${topic_parts[2]}`;

  console.log(`${topic_str} - ${message_str}`);

  let info = undefined;
  let tmp = displays;
  switch(topic_parts[3]){
  case "state":
    info = tmp[display_name];
    if(info == undefined){
      tmp[display_name] = {
        class: undefined,
        state: message_str,
      };
    } else {
      tmp[display_name] = {
        class: info.class,
        state: message_str,
      };
    }
    displays = tmp;
  break;
  case "class":
    info = tmp[display_name];
    console.log(info);
    if(info == undefined){
      tmp[display_name] = {
        class: message_str,
        state: undefined,
      };
    } else {
      tmp[display_name] = {
        class: message_str,
        state: info.state,
      };
    }
    displays = tmp;
  break;
  default:
    console.log(`Unhandled topic ${topic_str}`)
  }
});

</script>

<div class="displays">
  {#each Object.entries(displays) as [name, info]}
    <div>
      <p>{name}</p>
      <select bind:value={info.class} on:change={() => client.publish(`display/${name}/class`, info.class, { retain: true })}>
        {#each classes as c}
          <option value={c}>
            {c}
          </option>
        {/each}
      </select>
      <select bind:value={info.state} on:change={() => client.publish(`display/${name}/state`, info.state, { retain: true })}>
        {#each states as s}
          <option value={s}>
            {s}
          </option>
        {/each}
      </select>
    </div>
  {/each}
</div>
