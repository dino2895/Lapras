<template>
    <div class="relative w-full h-screen" id="map"></div>
    <!-- 釘選按鈕 -->
    <div class="absolute top-4 left-0 right-0 z-10 flex justify-center space-x-4">
        <button @click="toggleLayerVisibility('dogpoo')"
            class="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600 transition">
            狗便清潔箱
        </button>
        <button @click="toggleLayerVisibility('cleanbox')"
            class="bg-green-500 text-white px-4 py-2 rounded hover:bg-green-600 transition">
            行人專用清潔箱
        </button>
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

export default defineComponent({
    name: 'MapView',
    setup() {
        const mapInstance = ref<mapboxgl.Map | null>(null);

        // 圖層可見性狀態
        const layersVisibility = ref({
            dogpoo: true,
            cleanbox: true,
        });

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
                } else {
                    console.error(`Layer ${layerId} does not exist.`);
                }
            } catch (error) {
                console.error('An error occurred in toggleLayerVisibility:', error);
            }
        };

        // // 從 trashcar-1 圖層中提取點並繪製路徑
        // const drawRouteWithTrashcarData = () => {
        //     if (!mapInstance.value) {
        //         console.error('Map instance is not initialized.');
        //         return;
        //     }

        //     const features = mapInstance.value.queryRenderedFeatures({
        //         layers: ['trashcar-1'], // 指定 trashcar-1 圖層
        //     });

        //     if (features.length === 0) {
        //         console.error('No features found in trashcar-1 layer.');
        //         return;
        //     }

        //     // 提取 trashcar-1 圖層的所有坐標
        //     const coordinates = features.map((feature) => {
        //         return feature.geometry.coordinates;
        //     });

        //     if (coordinates.length === 0) {
        //         console.error('No coordinates found in trashcar-1 features.');
        //         return;
        //     }

        //     // 使用 Mapbox Directions API 繪製經過所有 trashcar-1 點的路徑
        //     const directions = new MapboxDirections({
        //         accessToken: mapboxgl.accessToken,
        //         unit: 'metric',
        //         profile: 'mapbox/driving', // 可以選擇 'mapbox/walking', 'mapbox/cycling', 'mapbox/driving'
        //         interactive: false, // 禁止互動模式
        //         controls: {
        //             inputs: false, // 隱藏輸入框
        //             instructions: true, // 顯示導航說明
        //         },
        //     });

        //     mapInstance.value.addControl(directions, 'top-left');

        //     // 設置起點
        //     directions.setOrigin(coordinates[0]);

        //     // 將剩下的坐標設為途徑點，最後一個點設為終點
        //     for (let i = 1; i < coordinates.length - 1; i++) {
        //         directions.addWaypoint(i - 1, coordinates[i]);
        //     }

        //     // 設置終點
        //     directions.setDestination(coordinates[coordinates.length - 1]);
        // };

        // 繪製路徑的函數
        const drawRouteWithTrashcarData = async () => {
            // 確保地圖和 trashcar-1 圖層已經加載
            if (!mapInstance.value) return;

            // 抓取 trashcar-1 圖層中的所有點
            const features = mapInstance.value.queryRenderedFeatures({
                layers: ['trashcar-1'], // 指定 trashcar-1 圖層
            });

            if (features.length === 0) {
                console.error('No features found in trashcar-1 layer.');
                return;
            }

            // 提取所有點的座標
            const coordinates = features.map((feature) => feature.geometry.coordinates);

            if (coordinates.length < 2) {
                console.error('Insufficient points to draw a route.');
                return;
            }

            try {
                // 通過 Mapbox Directions API 獲取路徑
                const directionsUrl = `https://api.mapbox.com/directions/v5/mapbox/driving/${coordinates
                    .map((coord) => coord.join(','))
                    .join(';')}?geometries=geojson&access_token=${mapboxgl.accessToken}`;

                const response = await fetch(directionsUrl);
                const data = await response.json();

                if (data.routes && data.routes.length > 0) {
                    const route = data.routes[0].geometry;

                    // 添加路徑到地圖
                    mapInstance.value.addLayer({
                        id: 'route',
                        type: 'line',
                        source: {
                            type: 'geojson',
                            data: {
                                type: 'Feature',
                                properties: {},
                                geometry: route,
                            },
                        },
                        layout: {
                            'line-join': 'round',
                            'line-cap': 'round',
                        },
                        paint: {
                            'line-color': '#3b9ddd',
                            'line-width': 4,
                        },
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

        const pointsJSON: GeoJSONFeatureCollection = {
            type: 'FeatureCollection',
            features: [
                {
                    type: 'Feature',
                    geometry: {
                        type: 'Point',
                        coordinates: [121.540592, 25.056111], // 經度和緯度
                    },
                    properties: {
                        title: '所在地',
                    },
                },
            ],
        };

        const updateUserLocation = (coords: [number, number]) => {
            pointsJSON.features[0].geometry.coordinates = coords;

            const source = mapInstance.value?.getSource('points');

            // 確認 source 是一個 GeoJSONSource
            if (source && (source as mapboxgl.GeoJSONSource).setData) {
                (source as mapboxgl.GeoJSONSource).setData(pointsJSON);
            } else {
                console.error("Source 'points' is not a GeoJSONSource or does not support setData.");
            }
        };

        onMounted(() => {
            mapboxgl.accessToken =
                'pk.eyJ1IjoicmljaDc0MjAiLCJhIjoiY20wa3B2ZnlxMWJraDJrb2I1a2I4ZzMwcSJ9.MQC2ef9isDmw5Uc37uiqeg'; // 替換成你的 Mapbox API 金鑰
            var userCoords: [number, number] = [121.540592, 25.056111];

            // 獲取用戶位置
            if (navigator.geolocation) {
                navigator.geolocation.getCurrentPosition(
                    (position) => {
                        userCoords = [position.coords.longitude, position.coords.latitude];

                        // 更新地圖中心到用戶GPS位址
                        mapInstance.value!.setCenter(userCoords);

                        // 更新GeoJSON圖層數據
                        updateUserLocation(userCoords);
                    },
                    (error) => {
                        console.error('Error getting user location:', error);
                    }
                );
            } else {
                console.error('Geolocation is not supported by this browser.');
            }

            mapInstance.value = new mapboxgl.Map({
                container: 'map', // 對應上面的 id="map"
                style: 'mapbox://styles/rich7420/cm0mii7r6002y01r3ao4pfbag', // 地圖樣式
                center: userCoords, // 設定地圖中心 [經度, 緯度]
                zoom: 12.5, // 設定初始縮放級別
                pitch: 45, // 攝像機俯仰角度
                bearing: -17.6, // 攝像機方向角度
            });

            // 添加中文語言支持
            mapInstance.value.addControl(new MapboxLanguage({ defaultLanguage: 'zh-Hant' }));

            // 加載圖片並添加到地圖上
            mapInstance.value.loadImage(imagePath, (error, image) => {
                if (error) {
                    console.error('圖片加載失敗:', error);
                    return;
                }

                if (image) {
                    console.log('圖片加載成功');
                    mapInstance.value!.addImage('pointImg', image);

                    mapInstance.value!.on('load', () => {
                        // 添加 GeoJSON 圖層
                        mapInstance.value!.addLayer({
                            id: 'points',
                            type: 'symbol',
                            source: {
                                type: 'geojson',
                                data: pointsJSON,
                            },
                            layout: {
                                'icon-image': 'pointImg',
                                'icon-size': 0.05,
                            },
                        });

                        // 點擊事件處理
                        mapInstance.value!.on('click', (event) => {
                            drawRouteWithTrashcarData();

                            const features = mapInstance.value!.queryRenderedFeatures(event.point, {
                                layers: ['dogpoo', 'cleanbox'], // 只查詢這兩個圖層
                            });

                            if (features.length) {
                                const clickedFeature = features[0];
                                const coordinates =
                                    clickedFeature.geometry?.type === 'Point'
                                        ? clickedFeature.geometry.coordinates
                                        : null;

                                if (clickedFeature.properties && clickedFeature.properties.title && coordinates) {
                                    alert(
                                        `You clicked on: ${clickedFeature.properties.title}\nCoordinates: [${coordinates[0]}, ${coordinates[1]}]`
                                    );
                                } else {
                                    console.log('No valid properties or coordinates found on clicked feature.');
                                }
                            } else {
                                console.log('No feature found at clicked location.');
                            }
                        });

                        // 改變游標形狀以提示用戶
                        mapInstance.value!.on('mousemove', (event) => {
                            const features = mapInstance.value!.queryRenderedFeatures(event.point, {
                                layers: ['dogpoo', 'cleanbox'],
                            });

                            mapInstance.value!.getCanvas().style.cursor = features.length ? 'pointer' : '';
                        });

                        // 添加地形
                        mapInstance.value!.addSource('mapbox-dem', {
                            type: 'raster-dem',
                            url: 'mapbox://mapbox.terrain-rgb',
                            tileSize: 512,
                            maxzoom: 14,
                        });

                        mapInstance.value!.setTerrain({ source: 'mapbox-dem', exaggeration: 1.5 });

                        // 添加 3D 建築物
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
                                                    ['get', 'height'],
                                                ],
                                                'fill-extrusion-base': [
                                                    'interpolate',
                                                    ['linear'],
                                                    ['zoom'],
                                                    15,
                                                    0,
                                                    16.05,
                                                    ['get', 'min_height'],
                                                ],
                                                'fill-extrusion-opacity': 0.6,
                                            },
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

                        console.log('Layers are loaded and 3D effects are added.');
                    });
                }
            });
        });

        return {
            toggleLayerVisibility,
        };
    },
});
</script>