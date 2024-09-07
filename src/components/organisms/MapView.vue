<template>
  <div class="w-full h-screen" id="map"></div>
  <!-- 選單按鈕 -->
  <div class="absolute top-4 left-0 right-0 z-10 flex justify-center space-x-4">
    <button
      @click="toggleMenu"
      class="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600 transition"
    >
      選單
    </button>
  </div>

  <!-- 選單內容 -->
  <transition name="slide">
    <div v-show="showMenu" class="absolute top-12 left-0 right-0 bg-white shadow-lg z-20 p-4">
      <button
        @click="toggleLayerVisibility('dogpoo')"
        class="block mb-2 bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600 transition"
      >
        狗便清潔箱
      </button>
      <button
        @click="toggleLayerVisibility('cleanbox')"
        class="block bg-green-500 text-white px-4 py-2 rounded hover:bg-green-600 transition"
      >
        行人專用清潔箱
      </button>
      <button
        @click="toggleAllTrashcarLayersVisibility"
        class="block bg-yellow-500 text-gray px-4 py-2 rounded hover:bg-yellow-500 transition"
      >
        垃圾車站點
      </button>
    </div>
  </transition>

  <!-- 側邊欄 -->
  <transition name="slide">
    <div
      v-show="showSidebar"
      class="fixed top-0 right-0 bottom-0 bg-white w-80 p-4 shadow-lg z-20 transition-transform transform translate-x-0"
    >
      <button @click="toggleSidebar" class="absolute top-4 left-4 text-gray-600">
        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M6 18L18 6M6 6l12 12"
          ></path>
        </svg>
      </button>
      <h2 class="text-lg font-bold mb-2">___提醒</h2>
      <div class="mb-4">
        <input
          v-model.number="alarmMinutes"
          type="number"
          placeholder="設置鬧鐘分鐘"
          class="border p-2 w-full mb-2"
        />
        <button
          @click="setAlarm"
          class="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600 transition"
        >
          設定鬧鐘
        </button>
      </div>
      <ul>
        <li
          v-for="(alarm, index) in alarms"
          :key="index"
          class="flex justify-between items-center mb-2"
        >
          <span>{{ alarm.minutes }} 分鐘</span>
          <span>{{ alarm.timeRemaining }} 秒後響</span>
          <button @click="removeAlarm(index)" class="text-red-500">刪除</button>
        </li>
      </ul>
    </div>
  </transition>

  <!-- 鬧鐘訊息 -->
  <div
    v-if="alarmMessage"
    class="absolute top-1/4 left-1/2 transform -translate-x-1/2 z-10 bg-red-500 text-white px-4 py-2 rounded"
  >
    {{ alarmMessage }}
  </div>

  <!-- 開關側邊欄按鈕 -->
  <button
    @click="toggleSidebar"
    class="fixed top-4 right-4 z-20 bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600 transition"
  >
    提醒
  </button>
</template>


<script lang="ts">
import { defineComponent, onMounted, ref } from 'vue';
import mapboxgl from 'mapbox-gl';
import 'mapbox-gl/dist/mapbox-gl.css';
import MapboxLanguage from '@mapbox/mapbox-gl-language';
import imagePath from '@/assets/images/geo-point.png';

export default defineComponent({
  name: 'MapView',
  setup() {
    const mapInstance = ref<mapboxgl.Map | null>(null);
    const showSidebar = ref(false); // 控制側邊欄顯示
    const showMenu = ref(false); // 控制選單顯示

    // 圖層可見性狀態
    const layersVisibility = ref({
      dogpoo: true,
      cleanbox: true
    });

    // 切換圖層可見性
    const toggleLayerVisibility = (layerId: keyof typeof layersVisibility.value) => {
      if (!mapInstance.value) return;

      const visibility = layersVisibility.value[layerId];
      const newOpacity = visibility ? 0 : 1;

      if (mapInstance.value.getLayer(layerId)) {
        mapInstance.value.setPaintProperty(layerId, 'circle-opacity', newOpacity);
        layersVisibility.value[layerId] = !visibility;
      }
    };

    // 鬧鐘功能
    const alarmMinutes = ref(0); // 設定鬧鐘分鐘
    const alarmTimeout = ref<NodeJS.Timeout | null>(null); // 計時器
    const alarmMessage = ref<string | null>(null); // 顯示鬧鐘訊息
    const alarms = ref<
      Array<{
        minutes: number;
        timeRemaining: number;
        intervalId: NodeJS.Timeout | null;
      }>
    >([]); // 鬧鐘清單

    const setAlarm = () => {
      if (alarmTimeout.value) clearTimeout(alarmTimeout.value);

      const timeInMs = alarmMinutes.value * 60 * 1000;
      if (timeInMs > 0) {
        alarmTimeout.value = setTimeout(() => {
          alarmMessage.value = '垃圾車來囉！';
          setTimeout(() => (alarmMessage.value = null), 5000); // 鬧鐘訊息顯示5秒
        }, timeInMs);

        // 添加到鬧鐘清單並啟動倒數計時
        const intervalId = setInterval(() => {
          alarms.value = alarms.value.map((alarm) => {
            if (alarm.timeRemaining > 0) {
              return {
                ...alarm,
                timeRemaining: alarm.timeRemaining - 1
              };
            } else {
              clearInterval(intervalId);
              return alarm;
            }
          });
        }, 1000);

        alarms.value.push({
          minutes: alarmMinutes.value,
          timeRemaining: Math.floor(timeInMs / 1000),
          intervalId
        });
      }
    };

    const removeAlarm = (index: number) => {
      const alarm = alarms.value[index];
      if (alarm.intervalId) {
        clearInterval(alarm.intervalId);
      }
      alarms.value.splice(index, 1);
    };

    const toggleSidebar = () => {
      showSidebar.value = !showSidebar.value;
    };

    const toggleMenu = () => {
      showMenu.value = !showMenu.value;
    };

    onMounted(() => {
      // 設置 Mapbox 訪問權限
      mapboxgl.accessToken =
        'pk.eyJ1IjoicmljaDc0MjAiLCJhIjoiY20wa3B2ZnlxMWJraDJrb2I1a2I4ZzMwcSJ9.MQC2ef9isDmw5Uc37uiqeg'; // 替換成你的 Mapbox API 金鑰
      const userCoords: [number, number] = [121.540592, 25.056111]; // 初始座標

      // 獲取用戶位置
      if (navigator.geolocation) {
        navigator.geolocation.getCurrentPosition(
          (position) => {
            const newCoords: [number, number] = [
              position.coords.longitude,
              position.coords.latitude
            ];
            mapInstance.value!.setCenter(newCoords);
            updateUserLocation(newCoords);
          },
          (error) => console.error('Error getting user location:', error)
        );
      } else {
        console.error('Geolocation is not supported by this browser.');
      }

      // 初始化地圖
      mapInstance.value = new mapboxgl.Map({
        container: 'map',
        style: 'mapbox://styles/rich7420/cm0mii7r6002y01r3ao4pfbag',
        center: userCoords,
        zoom: 12.5,
        pitch: 45,
        bearing: -17.6
      });

      // 加入中文語言支持
      mapInstance.value.addControl(new MapboxLanguage({ defaultLanguage: 'zh-Hant' }));

      // 加載圖像並將其添加到地圖
      mapInstance.value.loadImage(imagePath, (error, image) => {
        if (error || !image) {
          console.error('圖片加載失敗:', error);
          return;
        }

        mapInstance.value!.addImage('pointImg', image);

        mapInstance.value!.on('load', () => {
          mapInstance.value!.addLayer({
            id: 'points',
            type: 'symbol',
            source: {
              type: 'geojson',
              data: {
                type: 'FeatureCollection',
                features: [
                  {
                    type: 'Feature',
                    geometry: {
                      type: 'Point',
                      coordinates: [121.540592, 25.056111]
                    },
                    properties: {
                      title: '所在地'
                    }
                  }
                ]
              }
            },
            layout: {
              'icon-image': 'pointImg',
              'icon-size': 0.05
            }
          });
        });
      });
    });

    return {
      toggleLayerVisibility,
      alarmMinutes,
      setAlarm,
      alarmMessage,
      alarms,
      removeAlarm,
      showSidebar,
      toggleSidebar,
      showMenu,
      toggleMenu
    };
  }
});
</script>



<style scoped>
/* Define slide transition */
.slide-enter-active,
.slide-leave-active {
  transition: transform 0.3s ease;
}
.slide-enter, .slide-leave-to /* .slide-leave-active in <2.1.8 */ {
  transform: translateX(100%);
}

/* Style for menu */
.absolute {
  position: absolute;
}

.z-10 {
  z-index: 10;
}

.bg-white {
  background-color: white;
}

.shadow-lg {
  box-shadow:
    0 10px 15px -3px rgba(0, 0, 0, 0.1),
    0 4px 6px -2px rgba(0, 0, 0, 0.05);
}
</style>

