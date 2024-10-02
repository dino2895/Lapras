<template>
  <transition name="slide">
    <div
      v-show="showSidebar"
      class="fixed top-0 right-0 bottom-0 bg-white w-96 p-8 shadow-lg z-20 transition-transform transform translate-x-0"
    >
      <button
        @click="$emit('toggle-sidebar')"
        class="absolute top-4 right-4 text-gray-600 hover:text-gray-800 transition-colors duration-300"
      >
        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M6 18L18 6M6 6l12 12"
          ></path>
        </svg>
      </button>
      <h2 class="text-lg font-bold mb-6 pl-8">鬧鐘列表</h2>
      <div v-if="alarms.length === 0" class="text-center text-gray-500">尚未有已設定的鬧鐘</div>
      <ul v-else class="space-y-4">
        <li
          v-for="(alarm, index) in alarms"
          :key="index"
          class="flex flex-col p-6 bg-gray-100 rounded-lg shadow-sm"
        >
          <div class="flex flex-col space-y-2 text-gray-700">
            <span class="text-base">地點：{{ alarm.title }}</span>
            <span class="text-base">抵達時間：{{ alarm.arrivalTime }}</span>
            <span class="text-base">提前 {{ alarm.minutes }} 分鐘響</span>
            <span class="text-base">{{ formatTimeRemaining(alarm.timeRemaining) }}</span>
          </div>
          <button
            @click="$emit('remove-alarm', index)"
            class="mt-4 text-red-500 hover:text-red-600 transition-colors duration-300"
          >
            刪除
          </button>
        </li>
      </ul>
    </div>
  </transition>
</template>
  
<script>
export default {
  name: 'Sidebar',
  props: ['showSidebar', 'alarms'],
  emits: ['toggle-sidebar', 'remove-alarm'],
  methods: {
    formatTimeRemaining(seconds) {
      if (seconds <= 0) return '即將響';

      const roundedSeconds = Math.round(seconds);
      const hours = Math.floor(roundedSeconds / 3600);
      const minutes = Math.floor((roundedSeconds % 3600) / 60);
      const secs = roundedSeconds % 60;

      let timeString = '';
      if (hours > 0) timeString += `${hours} 小時 `;
      if (minutes > 0) timeString += `${minutes} 分鐘 `;
      if (secs > 0) timeString += `${secs} 秒 `;

      return timeString.trim() + '後響';
    }
  }
};
</script>
