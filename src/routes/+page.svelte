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

<h1>MQTT Test Page</h1>
