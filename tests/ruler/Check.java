import java.nio.file.*;
import com.fasterxml.jackson.databind.*;
import software.amazon.event.ruler.Ruler;

class Check {
    public static void main(String[] args) throws Exception {
        ObjectMapper mapper = new ObjectMapper();
        int count = 0;
        for (JsonNode item : mapper.readTree(Files.readString(Path.of("tests/fixtures/events.json")))) {
            String rule = Files.readString(Path.of("catalog", item.get("rule").asText() + ".json"));
            boolean actual = Ruler.matchesRule(item.get("event").toString(), rule);
            if (actual != item.get("matches").asBoolean()) throw new AssertionError(item.get("id"));
            System.out.println("PASS " + item.get("id").asText());
            count++;
        }
        System.out.println(count + " AWS Event Ruler fixtures passed");
    }
}
