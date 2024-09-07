<template>
    <div class="relative w-full h-screen" id="map"></div>
    <div class="absolute top-4 left-0 right-0 z-10 flex justify-center space-x-4">
        <button @click="toggleLayerVisibility('dogpoo')"
            class="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600 transition">
            狗便清潔箱
        </button>
        <button @click="toggleLayerVisibility('cleanbox')"
            class="bg-green-500 text-white px-4 py-2 rounded hover:bg-green-600 transition">
            行人專用清潔箱
        </button>
        <button @click="toggleAllTrashcarLayersVisibility"
            class="bg-yellow-300 text-gray px-4 py-2 rounded hover:bg-yellow-500 transition">
            垃圾車站點
        </button>
        <button @click="resetCenter" class="bg-red-500 text-white px-4 py-2 rounded hover:bg-red-600 transition">
            回到定位
        </button>
        <button @click="toggleNavigation"
            class="bg-purple-500 text-white px-4 py-2 rounded hover:bg-purple-600 transition">
            導航模式
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
        const directionsControl = ref<MapboxDirections | null>(null);
        const navigationEnabled = ref(false); // 導航功能的開關
        const destinationCoords = ref<[number, number] | null>(null);

        // 圖層可見性狀態
        const layersVisibility = ref({
            dogpoo: true,
            cleanbox: true,
        });

        //切換所有圖層
        const toggleAllTrashcarLayersVisibility = () => {
            if (!mapInstance.value) return;

            const layers = mapInstance.value.getStyle().layers;

            layers.forEach(layer => {
                if (layer.id.startsWith('trashcar-')) {
                    const currentVisibility = mapInstance.value.getLayoutProperty(layer.id, 'visibility');
                    const newVisibility = currentVisibility === 'visible' ? 'none' : 'visible';
                    mapInstance.value.setLayoutProperty(layer.id, 'visibility', newVisibility);
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
                } else {
                    console.error(`Layer ${layerId} does not exist.`);
                }
            } catch (error) {
                console.error('An error occurred in toggleLayerVisibility:', error);
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
                layers: [layerName],
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
                            geometry: route,
                        },
                    });

                    mapInstance.value.addLayer({
                        id: routeLayerId, // 固定的ID
                        type: 'line',
                        source: routeSourceId, // 使用固定的 source ID
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

        const pointsJSON = ref<GeoJSONFeatureCollection>({
            type: 'FeatureCollection',
            features: [
                {
                    type: 'Feature',
                    geometry: {
                        type: 'Point',
                        coordinates: [121.540592, 25.056111],
                    },
                    properties: {
                        title: '所在地',
                    },
                },
            ],
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
                console.log(pointsJSON.value.features[0].geometry.coordinates)
            } else {
                console.error('pointsJSON features array is empty or undefined.');
            }
        };

        //地圖假資料
        // const generateRandomCoords = (): [number, number] => {
        //     const baseLongitude = 121.540592;
        //     const baseLatitude = 25.056111;

        //     const randomOffset = () => (Math.random() - 0.5) * 0.001; // 隨機產生微小變化
        //     const newLongitude = baseLongitude + randomOffset();
        //     const newLatitude = baseLatitude + randomOffset();

        //     return [newLongitude, newLatitude];
        // };

        //設中心點
        const resetCenter = () => {
            if (mapInstance.value && pointsJSON.value.features[0].geometry.coordinates) {
                mapInstance.value.setCenter(pointsJSON.value.features[0].geometry.coordinates);
                mapInstance.value.setPitch(45);
                mapInstance.value.setBearing(-17.6);
                mapInstance.value.setZoom(17); // 可根據需求調整縮放等級
            }
        };

        // 切換導航模式
        const toggleNavigation = () => {
            if (navigationEnabled.value && directionsControl.value) {
                // 停用導航
                mapInstance.value?.removeControl(directionsControl.value);
                navigationEnabled.value = false;
                resetCenter();
            } else {
                // 啟用導航
                if (!mapInstance.value) return;

                directionsControl.value = new MapboxDirections({
                    accessToken: mapboxgl.accessToken,
                    unit: 'metric',
                    profile: 'mapbox/driving',
                });
                mapInstance.value.addControl(directionsControl.value, 'top-left');
                navigationEnabled.value = true;
            }
        };

        const navigateToCircleLayer = () => {
            if (mapInstance.value && destinationCoords.value && navigationEnabled.value && directionsControl.value) {
                // 設置導航起點和終點
                navigator.geolocation.getCurrentPosition((position) => {
                    const userCoords: [number, number] = [position.coords.longitude, position.coords.latitude];

                    directionsControl.value!.setOrigin(userCoords); // 設置起點為當前位置
                    directionsControl.value!.setDestination(destinationCoords.value); // 設置終點為點擊的圓圈層位置
                }, (error) => {
                    console.error('Error getting user location:', error);
                });
            }
        };

        // 點擊圓圈圖層，設置導航終點
        const handleCircleClick = (event: mapboxgl.MapMouseEvent) => {
            const features = mapInstance.value!.queryRenderedFeatures(event.point, {
                layers: ['dogpoo', 'cleanbox', 'trashcar-1', 'trashcar-2', 'trashcar-3', 'trashcar-4', 'trashcar-5', 'trashcar-6', 'trashcar-7', 'trashcar-8', 'trashcar-9'], // 指定圓圈圖層名稱
            });

            if (features.length > 0) {
                const clickedFeature = features[0];
                destinationCoords.value = clickedFeature.geometry.coordinates;

                // 啟動導航
                if (navigationEnabled.value) {
                    navigateToCircleLayer();
                }
            }
        };

        onMounted(() => {
            mapboxgl.accessToken =
                'pk.eyJ1IjoicmljaDc0MjAiLCJhIjoiY20wa3B2ZnlxMWJraDJrb2I1a2I4ZzMwcSJ9.MQC2ef9isDmw5Uc37uiqeg';
            var userCoords: [number, number] = [121.540592, 25.056111];

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

            mapInstance.value = new mapboxgl.Map({
                container: 'map',
                style: 'mapbox://styles/rich7420/cm0mii7r6002y01r3ao4pfbag',
                center: userCoords,
                zoom: 17,
                pitch: 45,
                bearing: -17.6,
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
                            data: pointsJSON.value,  // 使用初始的 GeoJSON 數據
                        });

                        // 添加圖層
                        mapInstance.value!.addLayer({
                            id: 'points',
                            type: 'symbol',
                            source: 'points',
                            layout: {
                                'icon-image': 'pointImg',
                                'icon-size': 0.05,
                            },
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
                                layers: ['dogpoo', 'cleanbox', 'trashcar-1', 'trashcar-2', 'trashcar-3', 'trashcar-4', 'trashcar-5', 'trashcar-6', 'trashcar-7', 'trashcar-8', 'trashcar-9'],
                            });

                            if (features.length) {
                                const clickedFeature = features[0];
                                console.log('Clicked feature:', clickedFeature);  // 調試點擊功能

                                const coordinates =
                                    clickedFeature.geometry?.type === 'Point'
                                        ? clickedFeature.geometry.coordinates
                                        : null;

                                const titleKey = Object.keys(clickedFeature.properties).find(key => key.trim() === 'title');
                                const title = clickedFeature.properties[titleKey];
                                if (clickedFeature.properties && title && coordinates) {
                                    alert(
                                        `此地點位於: ${title}\nCoordinates: [${coordinates[0]}, ${coordinates[1]}]`
                                    );
                                } else {
                                    console.log('No valid properties or coordinates found on clicked feature.');
                                }
                            } else {
                                console.log('No feature found at clicked location.');
                            }
                        });


                        mapInstance.value!.on('mousemove', (event) => {
                            const features = mapInstance.value!.queryRenderedFeatures(event.point, {
                                layers: ['dogpoo', 'cleanbox', 'trashcar-1', 'trashcar-2', 'trashcar-3', 'trashcar-4', 'trashcar-5', 'trashcar-6', 'trashcar-7', 'trashcar-8', 'trashcar-9'],
                            });

                            mapInstance.value!.getCanvas().style.cursor = features.length ? 'pointer' : '';
                        });
                        mapInstance.value!.addSource('mapbox-dem', {
                            type: 'raster-dem',
                            url: 'mapbox://mapbox.terrain-rgb',
                            tileSize: 512,
                            maxzoom: 14,
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
                                        const coords: [number, number] = [position.coords.longitude, position.coords.latitude];
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
                    });
                }
            });
        });

        return {
            toggleLayerVisibility,
            toggleAllTrashcarLayersVisibility,
            resetCenter,
            toggleNavigation,
        };
    },
});
</script>

<style lang="css">
.mapboxgl-ctrl-directions {
    max-width: 12rem;
    width: 100%;
    padding: 0.75rem; 
    background-color: white;
    border-radius: 0.375rem;
    box-shadow: 0 3px 5px rgba(0, 0, 0, 0.1);
}

.mapboxgl-ctrl-directions .mapbox-directions-origin,
.mapboxgl-ctrl-directions .mapbox-directions-destination {
    display: none !important;
    background-color: #f7fafc;
    border-radius: 0.375rem;
    font-size: 0.75rem;
    padding: 0.4rem;
    box-shadow: 0 1px 2px rgba(0, 0, 0, 0.1);
}

.mapboxgl-ctrl-directions .directions-icon-reverse {
    display: none !important;
}

.mapboxgl-ctrl-directions .mapbox-directions-profile {
    display: flex !important;
    pointer-events: auto;
    background-color: #ebf8ff;
    color: #3182ce;
    font-weight: 600;
    padding: 0.4rem 0.75rem; 
    border-radius: 0.25rem; 
}

.mapboxgl-ctrl-directions .mapbox-directions-route-summary {
    background-color: #cfe0ff;
    padding: 0.75rem;
    border-radius: 0.375rem;
    color: #2a4365;
}

</style>
