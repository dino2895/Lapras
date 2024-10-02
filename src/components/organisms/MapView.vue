<template>
  <div class="relative w-full h-screen">
    <div id="map" class="w-full h-full"></div>
    <MenuButtons @toggle-menu="toggleMenu" @reset-center="resetCenter" />
    <MenuContent v-model:showMenu="showMenu" :mapInstance="mapInstance" @toggle-layer-visibility="toggleLayerVisibility"
      @toggle-all-trashcar-layers-visibility="toggleAllTrashcarLayersVisibility" @reset-center="resetCenter"
      @toggle-navigation="toggleNavigation" @toggle-sidebar="toggleSidebar" />
    <Sidebar v-show="showSidebar" :show-sidebar="showSidebar" :alarms="alarms" @toggle-sidebar="toggleSidebar"
      @remove-alarm="removeAlarm" />
  </div>
</template>

<script lang="ts">
import { defineComponent, onMounted, ref } from 'vue';
import mapboxgl from 'mapbox-gl';
import 'mapbox-gl/dist/mapbox-gl.css';
import MapboxLanguage from '@mapbox/mapbox-gl-language';
import MapboxDirections from '@mapbox/mapbox-gl-directions/dist/mapbox-gl-directions';
import '@mapbox/mapbox-gl-directions/dist/mapbox-gl-directions.css';
import imagePath from '@/assets/images/geo-point.png';
import MenuButtons from '../molecules/MenuButtons.vue';
import MenuContent from '../molecules/MenuContent.vue';
import Sidebar from '../molecules/Side.vue';

export default defineComponent({
  name: 'MapView',
  components: {
    MenuButtons,
    MenuContent,
    Sidebar
  },
  setup() {
    const mapInstance = ref<mapboxgl.Map | null>(null);
    const directionsControl = ref<MapboxDirections | null>(null);
    const navigationEnabled = ref(false); // 導航功能的開關
    const destinationCoords = ref<[number, number] | null>(null);
    const showSidebar = ref(false); // 控制側邊欄顯示
    const showMenu = ref(false); // 控制選單顯示

    const sendNotification = (message) => {
      // 檢查瀏覽器是否支援 Notification API
      if (!("Notification" in window)) {
        showNotification(message); // 使用UI通知
        return;
      }

      // 檢查 Notification 權限狀態
      if (Notification.permission === "granted") {
        // 如果權限已獲得，顯示系統通知並顯示UI通知
        new Notification(message);
        showNotification(message);
      } else if (Notification.permission !== "denied") {
        // 如果權限未決定，請求通知權限
        Notification.requestPermission().then(permission => {
          if (permission === "granted") {
            new Notification(message);
          }
          showNotification(message); // 即使權限未決定，仍然顯示UI通知
        });
      } else {
        // 如果權限被拒絕，只顯示UI通知
        showNotification(message);
      }
    };

    const showNotification = (message) => {
      // 找到或創建一個用於顯示通知的元素
      const notificationElement = document.createElement('div');
      notificationElement.className = 'notification';
      notificationElement.textContent = message;

      notificationElement.style.position = 'fixed';
      notificationElement.style.bottom = '20px';
      notificationElement.style.left = '50%';  // 將通知居中顯示
      notificationElement.style.transform = 'translateX(-50%)';  // 水平居中的平移
      notificationElement.style.backgroundColor = '#2a4365';  // 深藍色背景，提升視覺對比度
      notificationElement.style.color = '#ffffff';  // 純白色文字，確保清晰可讀
      notificationElement.style.padding = '14px 20px';  // 調整 padding 讓內容更舒適
      notificationElement.style.borderRadius = '8px';  // 圓角處理，增加柔和感
      notificationElement.style.boxShadow = '0 4px 15px rgba(0, 0, 0, 0.3)';  // 增強陰影效果
      notificationElement.style.zIndex = '1000';
      notificationElement.style.fontFamily = 'Arial, sans-serif';
      notificationElement.style.fontSize = '16px';  // 增加字體大小，適合手機顯示
      notificationElement.style.transition = 'opacity 0.3s ease, transform 0.3s ease';
      notificationElement.style.opacity = '0.95';  // 增加透明度，讓背景更柔和

      // 針對移動設備的最大寬度設定
      notificationElement.style.maxWidth = '90%';  // 限制寬度，避免在手機屏幕上過大
      notificationElement.style.width = 'auto';  // 自動調整寬度以適應內容

      // 進場動畫效果
      setTimeout(() => {
        notificationElement.style.opacity = '1';  // 漸變顯示
        notificationElement.style.transform = 'translateX(-50%) translateY(0)';  // 居中位置並顯示
      }, 10);



      // 將通知元素加入到文件中
      document.body.appendChild(notificationElement);

      // 設定一段時間後自動消失
      setTimeout(() => {
        notificationElement.remove();
      }, 3000); // 3秒後消失
    };


    // 圖層可見性狀態
    const layersVisibility = ref({
      dogpoo: true,
      cleanbox: true
    });

    //切換所有圖層
    const toggleAllTrashcarLayersVisibility = () => {
      if (!mapInstance.value) return;

      const layers = mapInstance.value.getStyle().layers;
      let isVisible = false; // 用於追蹤新的可見性狀態

      layers.forEach((layer) => {
        if (layer.id.startsWith('trashcar-')) {
          const currentVisibility = mapInstance.value.getLayoutProperty(layer.id, 'visibility');
          const newVisibility = currentVisibility === 'visible' ? 'none' : 'visible';
          mapInstance.value.setLayoutProperty(layer.id, 'visibility', newVisibility);

          // 更新 isVisible 變量
          if (newVisibility === 'visible') {
            isVisible = true;
          }
        }
      });

    };

    // 切換圖層可見性
    const toggleLayerVisibility = (layerId: keyof typeof layersVisibility.value) => {
      try {
        if (!mapInstance.value) throw new Error('Map instance is not initialized.');

        const visibility = layersVisibility.value[layerId];
        const newOpacity = visibility ? 0 : 1;

        if (mapInstance.value.getLayer(layerId)) {
          // 只適用circle類型圖層
          mapInstance.value.setPaintProperty(layerId, 'circle-opacity', newOpacity);
          layersVisibility.value[layerId] = !visibility;

          // 根據圖層可見性顯示對應的 alert
          if (!visibility) {
            sendNotification(`${layerId === 'dogpoo' ? '狗便清潔箱' : '行人專用清潔箱'} 顯示`);
          } else {
            sendNotification(`${layerId === 'dogpoo' ? '狗便清潔箱' : '行人專用清潔箱'} 隱藏`);
          }
        } else {
          console.error(`Layer ${layerId} does not exist.`);
        }
      } catch (error) {
        console.error('An error occurred in toggleLayerVisibility:', error);
      }
    };

    // 鬧鐘相關狀態
    const alarms = ref<
      { minutes: number; arrivalTime: string; timeRemaining: number; interval: NodeJS.Timeout; title: string }[]
    >([]);


    // 格式化剩餘時間
    function formatTimeRemaining(seconds: number): string {
      if (seconds <= 0) return '即將響';

      const hours = Math.floor(seconds / 3600);
      const minutes = Math.floor((seconds % 3600) / 60);
      const secs = Math.floor(seconds % 60);

      let timeString = '';
      if (hours > 0) timeString += `${hours} 小時 `;
      if (minutes > 0) timeString += `${minutes} 分鐘 `;
      if (secs > 0) timeString += `${secs} 秒 `;

      return timeString.trim() + '後響';
    }

    // 設定鬧鐘並保存至 localStorage
    const setAlarm = (minutes: number, arrivalTime: number, title: string) => {
      if (minutes > 0 && arrivalTime) {
        const hours = Math.floor(arrivalTime / 100);
        const minutesOfArrival = arrivalTime % 100;
        const now = new Date();
        const alarmDate = new Date(
          now.getFullYear(),
          now.getMonth(),
          now.getDate(),
          hours,
          minutesOfArrival - minutes
        );
        console.log(minutes)
        const alarm = {
          minutes,
          title,
          alarmTime: alarmDate.getTime(), // 保存鬧鐘抵達時間（UNIX時間戳）
          arrivalTimeFormatted: hours + "：" + minutesOfArrival
        };

        // 保存至 localStorage
        let alarmList = JSON.parse(localStorage.getItem('alarms') || '[]');
        alarmList.push(alarm);
        localStorage.setItem('alarms', JSON.stringify(alarmList));

        sendNotification(`鬧鐘已設定，將在 ${minutes} 分鐘後提醒你`);
      } else {
        sendNotification('請輸入有效的時間');
      }
    };

    // 每秒更新鬧鐘剩餘時間
    const updateAlarms = () => {
      const now = new Date().getTime();
      let alarmList = JSON.parse(localStorage.getItem('alarms') || '[]');

      alarms.value = alarmList.map((alarm: any) => {
        const timeRemaining = Math.max(0, (alarm.alarmTime - now) / 1000);
        return {
          ...alarm,
          timeRemaining,
          formattedTime: formatTimeRemaining(timeRemaining),
        };
      });

      // 檢查是否有鬧鐘到達時間，響起鬧鐘
      alarms.value.forEach((alarm) => {
        if (alarm.timeRemaining <= 0) {
          sendNotification(`鬧鐘 ${alarm.title} 響起！`);
          // 移除已響起的鬧鐘
          removeAlarm(alarm.title);
        }
      });
    };


    // 從 localStorage 移除已響起的鬧鐘
    const removeAlarm = (title: string) => {
      let alarmList = JSON.parse(localStorage.getItem('alarms') || '[]');
      // 過濾掉與給定 title 相匹配的鬧鐘
      const updatedAlarmList = alarmList.filter((alarm: any) => alarm.title !== title);
      // 將更新後的鬧鐘列表存回 localStorage
      localStorage.setItem('alarms', JSON.stringify(updatedAlarmList));

      // 提示已移除
      sendNotification(`鬧鐘 ${title} 已被移除`);
    };


    const toggleSidebar = () => {
      showSidebar.value = !showSidebar.value;
    };

    const toggleMenu = () => {
      showMenu.value = !showMenu.value;
    };

    // 更新彈出框設置鬧鐘的邏輯
    const setAlarmInPopup = (minutes: number, arrivalTime: number, title: string, popup: mapboxgl.Popup) => {
      if (minutes > 0 && arrivalTime) {
        setAlarm(minutes, arrivalTime, title); // 使用 setAlarm 來設定鬧鐘
        popup.remove(); // 關閉彈出框
      } else {
        sendNotification('請輸入有效的分鐘數和到達時間');
      }
    };

    // 繪製路徑的函數
    const drawRouteWithTrashcarData = async (layerName) => {
      if (!mapInstance.value) return;

      const routeLayerId = 'route'; // 固定的ID
      const routeSourceId = 'route'; // 固定的 source ID

      if (mapInstance.value.getLayer(routeLayerId)) {
        mapInstance.value.removeLayer(routeLayerId);
      }
      if (mapInstance.value.getSource(routeSourceId)) {
        mapInstance.value.removeSource(routeSourceId);
      }

      const features = mapInstance.value.queryRenderedFeatures({
        layers: [layerName]
      });

      if (features.length === 0) {
        console.error(`No features found in ${layerName} layer.`);
        return;
      }

      const coordinates = features.map((feature) => feature.geometry.coordinates);

      if (coordinates.length < 2) {
        console.error('Insufficient points to draw a route.');
        return;
      }

      try {
        const directionsUrl = `https://api.mapbox.com/directions/v5/mapbox/driving/${coordinates
          .map((coord) => coord.join(','))
          .join(';')}?geometries=geojson&access_token=${mapboxgl.accessToken}`;

        const response = await fetch(directionsUrl);
        const data = await response.json();

        if (data.routes && data.routes.length > 0) {
          const route = data.routes[0].geometry;

          // 添加新的 source 和 layer，确保 source 和 layer 的 ID 是固定的
          mapInstance.value.addSource(routeSourceId, {
            type: 'geojson',
            data: {
              type: 'Feature',
              properties: {},
              geometry: route
            }
          });

          mapInstance.value.addLayer({
            id: routeLayerId, // 固定的ID
            type: 'line',
            source: routeSourceId, // 使用固定的 source ID
            layout: {
              'line-join': 'round',
              'line-cap': 'round'
            },
            paint: {
              'line-color': '#3b9ddd',
              'line-width': 4
            }
          });
        } else {
          console.error('No route data found from Directions API.');
        }
      } catch (error) {
        console.error('Error fetching route from Directions API:', error);
      }
    };

    // GeoJSON 數據
    interface GeoJSONFeature {
      type: 'Feature';
      geometry: {
        type: 'Point';
        coordinates: [number, number];
      };
      properties: {
        title: string;
      };
    }

    interface GeoJSONFeatureCollection {
      type: 'FeatureCollection';
      features: GeoJSONFeature[];
    }

    const pointsJSON = ref<GeoJSONFeatureCollection>({
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
    });

    const updateUserLocation = (coords: [number, number]) => {
      if (pointsJSON.value.features.length > 0) {
        pointsJSON.value.features[0].geometry.coordinates = coords;

        const source = mapInstance.value?.getSource('points');
        if (source && (source as mapboxgl.GeoJSONSource).setData) {
          (source as mapboxgl.GeoJSONSource).setData(pointsJSON.value);
        } else {
          console.error("Source 'points' is not a GeoJSONSource or does not support setData.");
        }
        console.log(pointsJSON.value.features[0].geometry.coordinates);
      } else {
        console.error('pointsJSON features array is empty or undefined.');
      }
    };
    const resetCenter = () => {
      if (mapInstance.value && pointsJSON.value.features[0].geometry.coordinates) {
        mapInstance.value.setCenter(pointsJSON.value.features[0].geometry.coordinates);
        mapInstance.value.setPitch(45);
        mapInstance.value.setBearing(-17.6);
        mapInstance.value.setZoom(15.8); // 可根據需求調整縮放等級
      }
    };

    // 切換導航模式
    const toggleNavigation = () => {
      if (navigationEnabled.value && directionsControl.value) {
        // 停用導航
        sendNotification('關閉導航');
        mapInstance.value?.removeControl(directionsControl.value);
        navigationEnabled.value = false;
        resetCenter();
      } else {
        // 啟用導航
        sendNotification('啟用導航');
        if (!mapInstance.value) return;

        directionsControl.value = new MapboxDirections({
          accessToken: mapboxgl.accessToken,
          unit: 'metric',
          profile: 'mapbox/driving'
        });
        mapInstance.value.addControl(directionsControl.value, 'top-left');
        navigationEnabled.value = true;
      }
    };

    const navigateToCircleLayer = (userCoords: [number, number]) => {
      if (
        mapInstance.value &&
        destinationCoords.value &&
        navigationEnabled.value &&
        directionsControl.value
      ) {
        directionsControl.value!.setOrigin(userCoords); // 設置起點為當前位置
        directionsControl.value!.setDestination(destinationCoords.value); // 設置終點為點擊的圓圈層位置
      }
    };

    // 點擊圓圈圖層，設置導航終點
    const handleCircleClick = (event: mapboxgl.MapMouseEvent) => {
      const features = mapInstance.value!.queryRenderedFeatures(event.point, {
        layers: [
          'dogpoo',
          'cleanbox',
          'trashcar-1',
          'trashcar-2',
          'trashcar-3',
          'trashcar-4',
          'trashcar-5',
          'trashcar-6',
          'trashcar-7',
          'trashcar-8',
          'trashcar-9'
        ] // 指定圓圈圖層名稱
      });

      if (features.length > 0) {
        const clickedFeature = features[0];
        destinationCoords.value = clickedFeature.geometry.coordinates;

        // 獲取使用者位置並導航
        if (navigationEnabled.value && navigator.geolocation) {
          navigator.geolocation.getCurrentPosition(
            (position) => {
              const userCoords: [number, number] = [
                position.coords.longitude,
                position.coords.latitude
              ];
              navigateToCircleLayer(userCoords);
            },
            (error) => {
              console.error('Error getting user location:', error);
            }
          );
        }
      } else {
        // 如果點擊非圓圈區域，彈出提示訊息
        sendNotification('請點選想去的站點');
      }
    };


    onMounted(() => {
      mapboxgl.accessToken =
        'pk.eyJ1IjoicmljaDc0MjAiLCJhIjoiY20wa3B2ZnlxMWJraDJrb2I1a2I4ZzMwcSJ9.MQC2ef9isDmw5Uc37uiqeg';
      var userCoords: [number, number] = [121.540592, 25.056111];

      // 獲取用戶位置
      if (navigator.geolocation) {
        navigator.geolocation.getCurrentPosition(
          (position) => {
            userCoords = [position.coords.longitude, position.coords.latitude];
            mapInstance.value!.setCenter(userCoords);
            updateUserLocation(userCoords);
          },
          (error) => {
            console.error('Error getting user location:', error);
          }
        );
      } else {
        console.error('Geolocation is not supported by this browser.');
      }

      // 初始化地圖
      mapInstance.value = new mapboxgl.Map({
        container: 'map',
        style: 'mapbox://styles/rich7420/cm0mii7r6002y01r3ao4pfbag',
        center: userCoords,
        zoom: 15.8,
        pitch: 45,
        bearing: -17.6
      });

      // 監聽點擊事件
      mapInstance.value!.on('click', handleCircleClick);

      mapInstance.value.addControl(new MapboxLanguage({ defaultLanguage: 'zh-Hant' }));

      mapInstance.value.loadImage(imagePath, (error, image) => {
        if (error) {
          console.error('圖片加載失敗:', error);
          return;
        }

        if (image) {
          mapInstance.value!.addImage('pointImg', image);

          mapInstance.value!.on('load', () => {
            // 添加 GeoJSON source
            mapInstance.value!.addSource('points', {
              type: 'geojson',
              data: pointsJSON.value // 使用初始的 GeoJSON 數據
            });

            // 添加圖層
            mapInstance.value!.addLayer({
              id: 'points',
              type: 'symbol',
              source: 'points',
              layout: {
                'icon-image': 'pointImg',
                'icon-size': 0.05
              }
            });

            mapInstance.value!.on('click', (event) => {
              const features = mapInstance.value!.queryRenderedFeatures(event.point);

              if (features.length > 0) {
                const clickedFeature = features[0];
                const layerId = clickedFeature.layer.id;

                if (layerId.startsWith('trashcar-') && clickedFeature.layer.type === 'circle') {
                  drawRouteWithTrashcarData(layerId);
                }
              }
            });

            mapInstance.value!.on('click', (event) => {
              const features = mapInstance.value!.queryRenderedFeatures(event.point, {
                layers: [
                  'dogpoo',
                  'cleanbox',
                  'trashcar-1',
                  'trashcar-2',
                  'trashcar-3',
                  'trashcar-4',
                  'trashcar-5',
                  'trashcar-6',
                  'trashcar-7',
                  'trashcar-8',
                  'trashcar-9'
                ]
              });

              if (features.length) {
                const clickedFeature = features[0];
                const coordinates =
                  clickedFeature.geometry?.type === 'Point'
                    ? clickedFeature.geometry.coordinates
                    : null;

                const titleKey = Object.keys(clickedFeature.properties).find(
                  (key) => key.trim() === 'title'
                );
                const title = clickedFeature.properties[titleKey];

                if (clickedFeature.properties && title && coordinates) {
                  const layerId = clickedFeature.layer.id;

                  // 只有以 'trashcar-' 開頭的圖層才會顯示帶抵達時間的彈出窗口
                  if (layerId.startsWith('trashcar-')) {
                    const arT = clickedFeature.properties['抵達時間'];
                    const hours = Math.floor(arT / 100); // 取整數部分為小時
                    const minutes = arT % 100; // 取餘數部分為分鐘
                    const formattedTime = `${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}`;

                    const popup = new mapboxgl.Popup()
                      .setLngLat([event.lngLat.lng, event.lngLat.lat])
                      .setHTML(
                        `
            <div class="p-4 bg-white rounded-lg shadow-lg">
              <h5 class="text-sm font-semibold mb-2 text-gray-800">地點：</br>${title}</h5>
              <p class="text-sm font-semibold mb-2 text-gray-800">垃圾車抵達時間${formattedTime}</p>
              <div class="mb-4">
                <label for="minutes" class="block text-sm font-medium text-gray-700">提前幾分鐘提醒：</label>
                <input type="number" id="minutes" placeholder="請輸入數字" class="mt-1 p-2 w-full border rounded-lg focus:ring-blue-500 focus:border-blue-500" />
              </div>
              <button id="setAlarm" class="w-full bg-blue-500 hover:bg-blue-600 text-white font-bold py-2 px-4 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-opacity-50">設定鬧鐘</button>
            </div>
          `
                      )
                      .addTo(mapInstance.value!);

                    document.getElementById('setAlarm')?.addEventListener('click', () => {
                      const minutes = parseInt(
                        (document.getElementById('minutes') as HTMLInputElement).value
                      );
                      const arrivalTime = clickedFeature.properties['抵達時間'];
                      console.log(arrivalTime)
                      setAlarmInPopup(minutes, arrivalTime, title, popup);
                    });
                  } else {
                    // 其他圖層只顯示 title
                    new mapboxgl.Popup()
                      .setLngLat([event.lngLat.lng, event.lngLat.lat])
                      .setHTML(
                        `
            <div class="p-4 bg-white rounded-lg shadow-lg">
              <h5 class="text-sm font-semibold mb-2 text-gray-800">地點：</br>${title}</h5>
            </div>
          `
                      )
                      .addTo(mapInstance.value!);
                  }
                }
              }
            });

            mapInstance.value!.on('mousemove', (event) => {
              const features = mapInstance.value!.queryRenderedFeatures(event.point, {
                layers: [
                  'dogpoo',
                  'cleanbox',
                  'trashcar-1',
                  'trashcar-2',
                  'trashcar-3',
                  'trashcar-4',
                  'trashcar-5',
                  'trashcar-6',
                  'trashcar-7',
                  'trashcar-8',
                  'trashcar-9'
                ]
              });

              mapInstance.value!.getCanvas().style.cursor = features.length ? 'pointer' : '';
            });

            mapInstance.value!.addSource('mapbox-dem', {
              type: 'raster-dem',
              url: 'mapbox://mapbox.terrain-rgb',
              tileSize: 512,
              maxzoom: 14
            });

            if (navigator.geolocation) {
              navigator.geolocation.getCurrentPosition(
                () => {
                  if (mapInstance.value) {
                    // 使用 pointsJSON 裡的座標來設置中心點
                    mapInstance.value.setCenter(pointsJSON.value.features[0].geometry.coordinates);
                  }
                },
                (error) => {
                  console.error('Error getting user location:', error);
                }
              );
            }

            // 假設中心點塗層已存在，更新數據
            // 定時更新使用者位置
            setInterval(() => {
              if (navigator.geolocation) {
                navigator.geolocation.getCurrentPosition(
                  (position) => {
                    const coords: [number, number] = [
                      position.coords.longitude,
                      position.coords.latitude
                    ];
                    updateUserLocation(coords);
                  },
                  (error) => {
                    console.error('Error getting location:', error);
                  }
                );
              }
            }, 5000);

            mapInstance.value!.setTerrain({ source: 'mapbox-dem', exaggeration: 1.5 });

            if (mapInstance.value) {
              const style = mapInstance.value.getStyle();
              if (style && style.layers) {
                const labelLayerId = style.layers.find(
                  (layer) => layer.type === 'symbol' && layer.layout?.['text-field']
                )?.id;

                if (labelLayerId) {
                  mapInstance.value.addLayer(
                    {
                      id: '3d-buildings',
                      source: 'composite',
                      'source-layer': 'building',
                      filter: ['==', 'extrude', 'true'],
                      type: 'fill-extrusion',
                      minzoom: 15,
                      paint: {
                        'fill-extrusion-color': '#aaa',
                        'fill-extrusion-height': [
                          'interpolate',
                          ['linear'],
                          ['zoom'],
                          15,
                          0,
                          16.05,
                          ['get', 'height']
                        ],
                        'fill-extrusion-base': [
                          'interpolate',
                          ['linear'],
                          ['zoom'],
                          15,
                          0,
                          16.05,
                          ['get', 'min_height']
                        ],
                        'fill-extrusion-opacity': 0.6
                      }
                    },
                    labelLayerId
                  );
                } else {
                  console.error('No symbol layer with text-field found.');
                }
              } else {
                console.error('No style or layers found in the map.');
              }
            } else {
              console.error('Map instance is not initialized.');
            }
          });
        }
      });
      setInterval(updateAlarms, 1000);
    });

    return {
      toggleLayerVisibility,
      toggleAllTrashcarLayersVisibility,
      resetCenter,
      toggleNavigation,
      setAlarm,
      alarms,
      updateAlarms,
      removeAlarm,
      showSidebar,
      toggleSidebar,
      toggleMenu,
      showMenu,
      mapInstance,
      directionsControl,
      navigationEnabled,
      destinationCoords,
      formatTimeRemaining
    };
  }
});
</script>



<style lang="css">
.setAlarmButton {
  background-color: yellow;
  border: none;
  padding: 10px 20px;
  font-size: 16px;
  cursor: pointer;
}

.mapboxgl-ctrl-directions {
  width: 100%;
  border-radius: 0.375rem;
  box-shadow: 0 3px 5px rgba(0, 0, 0, 0.1);
  min-width: 0;
  padding-left: 0px;
}

.mapbox-directions-profile input[type=radio]:checked+label:hover,
.mapbox-directions-profile input[type=radio]:checked+label {
  width: 59.5px;
  color: rgba(0, 0, 0, .75);
}

.mapboxgl-ctrl-directions .mapbox-directions-origin,
.mapboxgl-ctrl-directions .mapbox-directions-destination {
  display: none !important;
  background-color: #f7fafc;
  border-radius: 0.375rem;
  font-size: 0.75rem;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.1);
}

.mapboxgl-ctrl-directions .directions-control-directions {
  max-height: 150px !important;
  max-width: 80%;
  overflow-y: auto;
}

.mapboxgl-ctrl-directions .directions-icon-reverse {
  display: none !important;
}

.mapboxgl-ctrl-top-left .mapboxgl-ctrl {
  float: left;
  margin: 0;
}

.mapboxgl-ctrl-directions .mapbox-directions-profile {
  z-index: 10;
  display: flex !important;
  align-items: flex-start;
  pointer-events: auto;
  background: linear-gradient(135deg, #ebf8ff 0%, #cfe0ff 100%); /* 背景漸變效果 */
  color: #2a4365; /* 調整文字顏色更和諧 */
  font-weight: 600;
  border: 1px solid #3182ce;
  padding: 0.5rem 0.25rem;
  border-radius: 8px; /* 更圓潤的邊角 */
  white-space: nowrap;
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1); /* 添加柔和的陰影效果 */
  max-width: 230px;
  min-width: 0;
  margin: 10px 0;
  transition: transform 0.3s ease, box-shadow 0.3s ease; /* 增加平滑的過渡效果 */
}

.mapboxgl-ctrl-directions .mapbox-directions-profile:hover {
  transform: translateY(-2px); /* 提升效果 */
  box-shadow: 0 6px 12px rgba(0, 0, 0, 0.15); /* 增強陰影 */
}


.mapboxgl-ctrl-directions .mapbox-directions-route-summary {
  background-color: #cfe0ff;
  padding: 0.75rem;
  border-radius: 0.375rem;
  color: #2a4365;
}

/* Define slide transition */
.slide-enter-active,
.slide-leave-active {
  transition: transform 0.5s ease-in-out;
}

.slide-enter,
.slide-leave-to

/* .slide-leave-active in <2.1.8 */
  {
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

.style1 {
  display: flex;
  justify-content: flex-start;
}

.blue {
  color: #5ab4c5;
}

.white {
  color: white;
}
</style>
