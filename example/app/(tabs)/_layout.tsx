import FontAwesome from '@expo/vector-icons/FontAwesome';
import { Tabs } from 'expo-router';

export default function TabLayout() {
  return (
    <Tabs screenOptions={{ tabBarActiveTintColor: 'blue' }}>
      <Tabs.Screen
        name="index"
        options={{
          title: 'Play',
          headerShown: false,
          tabBarIcon: ({ color }) => <FontAwesome size={28} name="home" color={color} />,
        }}
      />
      <Tabs.Screen
        name="record"
        options={{
          title: 'Record',
          headerShown: false,
          tabBarIcon: ({ color }) => <FontAwesome size={28} name="music" color={color} />,
        }}
      />
      <Tabs.Screen
        name="vad"
        options={{
          title: 'VAD',
          headerShown: false,
          tabBarIcon: ({ color }) => <FontAwesome size={28} name="file-sound-o" color={color} />,
        }}
      />
    </Tabs>
  );
}
