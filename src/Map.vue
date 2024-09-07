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

        // 繪製路徑的函數
        const drawRouteWithTrashcarData = async () => {
            if (!mapInstance.value) return;

            // 抓取 trashcar-1 圖層中的所有點
            const features = mapInstance.value.queryRenderedFeatures({
                layers: ['trashcar-1'],
            });

            if (features.length === 0) {
                console.error('No features found in trashcar-1 layer.');
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
                        coordinates: [121.540592, 25.056111],
                    },
                    properties: {
                        title: '所在地',
                    },
                },
            ],
        };

        const updateUserLocation = (coords: [number, number]) => {
            pointsJSON.features[0].geometry.coordinates = coords;

            const source = mapInstance.value?.getSource('Points');

            if (source && (source as mapboxgl.GeoJSONSource).setData) {
                (source as mapboxgl.GeoJSONSource).setData(pointsJSON);
            } else {
                console.error("Source 'points' is not a GeoJSONSource or does not support setData.");
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

            mapInstance.value.addControl(new MapboxLanguage({ defaultLanguage: 'zh-Hant' }));

            mapInstance.value.loadImage(imagePath, (error, image) => {
                if (error) {
                    console.error('圖片加載失敗:', error);
                    return;
                }

                if (image) {
                    mapInstance.value!.addImage('pointImg', image);

                    mapInstance.value!.on('load', () => {
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

                        mapInstance.value!.on('click', (event) => {
                            const features = mapInstance.value!.queryRenderedFeatures(event.point, {
                                layers: ['dogpoo', 'cleanbox'],
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
                                        `You clicked on: ${title}\nCoordinates: [${coordinates[0]}, ${coordinates[1]}]`
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
                                layers: ['dogpoo', 'cleanbox'],
                            });

                            mapInstance.value!.getCanvas().style.cursor = features.length ? 'pointer' : '';
                        });
                        mapInstance.value!.addSource('mapbox-dem', {
                            type: 'raster-dem',
                            url: 'mapbox://mapbox.terrain-rgb',
                            tileSize: 512,
                            maxzoom: 14,
                        });

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
        };
    },
});
</script>
