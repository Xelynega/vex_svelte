<script>
import mqtt from "mqtt";
const client = mqtt.connect("ws://127.0.0.1:8883");

client.on("connect", () => {
  console.log("connected");
  client.subscribe("test", (err) => {
    if (err) {
      console.log(err);
    } else {
      console.log("subscribed");
    }
  });
});

client.on("message", (topic, message) => {
  let topic_str = topic.toString();
  let message_str = message.toString();

  console.log(`${topic_str} - ${message_str}`);
});

</script>

<div class="side-display container" style="border: 1px solid black;">
  <div class="score-grid">
    <p id="event-name">Mecha Mayhem 2024</p>
    <p id="timer">10:00</p>
    <p id="match">Qualifications 1</p>

    <p id="score-red">40</p>
    <p id="score-blue">120</p>

    <div class="teams" id="teams-red"><p>6659A</p><p>6659B</p></div>
    <div class="teams" id="teams-blue"><p>210Y</p><p>210Z</p></div>
  </div>
</div>

<div class="center-display container" style="border: 1px solid black;">
  <div class="score-grid">
    <p id="event-name">Mecha Mayhem 2024</p>
    <p id="timer">10:00</p>
    <p id="match">Qualifications 1</p>

    <p id="score-red">40</p>
    <p id="score-blue">120</p>

    <div class="teams" id="teams-red"><p>6659A</p><p>6659B</p></div>
    <div class="teams" id="teams-blue"><p>210Y</p><p>210Z</p></div>
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

  grid-template: 30% 40% 30% / 35% 30% 35%;

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
