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
import imagePath from '@/assets/images/geo-point.png';

export default defineComponent({
    name: 'MapView',
    setup() {
        const mapInstance = ref<mapboxgl.Map | null>(null);

        // 圖層可見性狀態
        const layersVisibility = ref({
            dogpoo: true,
            cleanbox: true
        });

        // 切換圖層可見性
        const toggleLayerVisibility = (layerId: keyof typeof layersVisibility.value) => {
            try {
                if (!mapInstance.value) throw new Error("Map instance is not initialized.");

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
                console.error("An error occurred in toggleLayerVisibility:", error);
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
                        title: '所在地'
                    }
                }
            ]
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
            mapboxgl.accessToken = 'pk.eyJ1IjoicmljaDc0MjAiLCJhIjoiY20wa3B2ZnlxMWJraDJrb2I1a2I4ZzMwcSJ9.MQC2ef9isDmw5Uc37uiqeg'; // 替換成你的 Mapbox API 金鑰
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
                zoom: 18, // 設定初始縮放級別
                pitch: 45,  // 攝像機俯仰角度
                bearing: -17.6 // 攝像機方向角度
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

                        // 在地圖上點擊來選取 dogpoo 或 cleanbox 圖層中的資料
                        mapInstance.value!.on('click', (event) => {
                            const features: GeoJSON.Feature<GeoJSON.Geometry, any>[] = mapInstance.value!.queryRenderedFeatures(event.point, {
                                layers: ['dogpoo', 'cleanbox'], // 只查詢這兩個圖層
                            });

                            if (features.length) {
                                const clickedFeature = features[0];
                                const coordinates = clickedFeature.geometry?.type === 'Point' ? clickedFeature.geometry.coordinates : null;

                                if (clickedFeature.properties && clickedFeature.properties.title && coordinates) {
                                    alert(`You clicked on: ${clickedFeature.properties.title}\nCoordinates: [${coordinates[0]}, ${coordinates[1]}]`);
                                } else {
                                    console.log('No valid properties or coordinates found on clicked feature.');
                                }
                            } else {
                                console.log('No feature found at clicked location.');
                            }
                        });

                        // 改變游標形狀以提示用戶
                        mapInstance.value!.on('mousemove', (event) => {
                            const features: GeoJSON.Feature<GeoJSON.Geometry, any>[] = mapInstance.value!.queryRenderedFeatures(event.point, {
                                layers: ['dogpoo', 'cleanbox'],
                            });

                            mapInstance.value!.getCanvas().style.cursor = features.length ? 'pointer' : '';
                        });

                        // 添加地形
                        mapInstance.value!.addSource('mapbox-dem', {
                            'type': 'raster-dem',
                            'url': 'mapbox://mapbox.terrain-rgb',
                            'tileSize': 512,
                            'maxzoom': 14
                        });

                        mapInstance.value!.setTerrain({ 'source': 'mapbox-dem', 'exaggeration': 1.5 });


                        // 確保 mapInstance 和 mapInstance.value 都存在
                        if (mapInstance.value) {
                            const style = mapInstance.value.getStyle();

                            // 確保 getStyle() 返回的結果和 layers 都存在
                            if (style && style.layers) {
                                const labelLayerId = style.layers.find(
                                    (layer) => layer.type === 'symbol' && layer.layout?.['text-field']
                                )?.id;

                                if (labelLayerId) {
                                    mapInstance.value.addLayer({
                                        'id': '3d-buildings',
                                        'source': 'composite',
                                        'source-layer': 'building',
                                        'filter': ['==', 'extrude', 'true'],
                                        'type': 'fill-extrusion',
                                        'minzoom': 15,
                                        'paint': {
                                            'fill-extrusion-color': '#aaa',
                                            'fill-extrusion-height': [
                                                'interpolate', ['linear'], ['zoom'],
                                                15, 0,
                                                16.05, ['get', 'height']
                                            ],
                                            'fill-extrusion-base': [
                                                'interpolate', ['linear'], ['zoom'],
                                                15, 0,
                                                16.05, ['get', 'min_height']
                                            ],
                                            'fill-extrusion-opacity': 0.6
                                        }
                                    }, labelLayerId);
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
