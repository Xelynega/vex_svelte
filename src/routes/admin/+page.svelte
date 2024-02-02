<script>
import mqtt from "mqtt";

// Consts
let topics = ['display/#', 'division/#'];
let states = ["init", "timer", "pre-game", "event-name", "alliance-selection", "break", "red-wins", "blue-wins", "prairies", "rockies", "ab-education", "ab-innovate", "tcenergy", "tourismcalgary", "westmech"];
let led_sizes = {
  "center": { width: 1176, height: 168 },
  "side": { width: 896, height: 128 }
}

const client = mqtt.connect("ws://metznet.ca:8883");
let displays = {};
let division_names = {};
let divisions = {};
let active_division = "1";

client.on("connect", () => {
  console.log("connected to mqtt");

  topics.forEach((topic) => {
    client.subscribe(topic, (err) => {
      if (err) {
        console.log(err);
      } else {
        console.log(`subscribed to topic '${topic}'`);
      }
    });
  });
});

client.on("message", (topic, message) => {
  let display_field_match = /^display\/(\d+)\/(\d+)\/(\w+)$/.exec(topic);
  let division_metadata_match = /^division\/(\d+)\/(\w+)$/.exec(topic);
  let division_stat_match = /^division\/(\d+)\/(\w+)\/(\d+)(?:\/(\w+))?$/.exec(topic);

  if(division_metadata_match) {
      let [_, division, type] = division_metadata_match;

      switch(type) {
        case "name":
          division_names[division] = message.toString();
          console.log(`Set division ${type} for ${division} to ${message.toString()}`)
          console.log(divisions);
          break;
        default:
          console.warn(`Unknown division metadata type: ${type}`);
      }
  } else if(division_stat_match) {
      let [_, division, matchType, matchNumber, type] = division_stat_match;
      type ||= "info";

      divisions[division] ||= {};
      divisions[division][matchType] ||= {};
      divisions[division][matchType][matchNumber] ||= {};

      divisions[division][matchType][matchNumber][type] ||= {};
  } else if(display_field_match) {
      let [_, division, field, type] = display_field_match;

      displays[division] ||= {};
      displays[division][field] ||= {};
      displays[division][field][type] = message.toString();
      console.log(displays[active_division]); 
  } else {
      console.warn(`no match for topic ${topic}`);
  }
});
</script>

<div class="displays">
  <select bind:value={active_division} on:change={() => console.log(`Changed: ${active_division}`)}>
    {#each Object.entries(division_names) as [division, name]}
      <option value={division} selected={active_division === division}>{name}</option>
    {/each}
  </select>

  {#if division_names[active_division] === undefined}
    <p>Division {active_division} undefined</p>
  {:else}
    <div class="division">
      <h2>{`${division_names[active_division]} Division`}</h2>
      {#each Object.entries(displays[active_division]) as [field, field_data] }
        <div class="field">
          <h3>Field {field}</h3>
          <iframe src="/?field={active_division}/{field}" width={led_sizes[field_data.class].width} height={led_sizes[field_data.class].height} title="Field {active_division}/{field}"></iframe>
          <br />
          <select bind:value={field_data.class} on:change={() => client.publish(`display/${active_division}/${field}/class`, field_data.class, { retain: true })}>
            {#each Object.entries(led_sizes) as [size, _]}
              <option value={size}>{size}</option>
            {/each}
          </select>
          <select bind:value={field_data.state} on:change={() => client.publish(`display/${active_division}/${field}/state`, field_data.state, { retain: true })}>
            {#each states as s}
              <option value={s}>
                {s}
              </option>
            {/each}
          </select>
        </div>
      {/each}
    </div>
  {/if}
</div>