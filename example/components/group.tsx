import { StyleSheet, Text, View } from "react-native";

export function Group(props: { name: string; children: React.ReactNode }) {
  return (
    <View style={styles.group}>
      <Text style={styles.groupHeader}>{props.name}</Text>
      {props.children}
    </View>
  );
}

const styles = StyleSheet.create({
  groupHeader: {
    fontSize: 20,
    marginBottom: 20,
    textAlign: "center"
  },
  group: {
    marginVertical: 10,
    marginHorizontal: 20,
    backgroundColor: "#fff",
    borderRadius: 10,
    padding: 20
  }
});