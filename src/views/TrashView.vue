<script setup lang="ts">
import { computed, ref, onMounted, onBeforeUnmount } from 'vue';
import { RouterLink, useRoute } from 'vue-router';
import { useFormStore } from '@/stores/form';
import { useUserStore } from '@/stores/user';
import { storeToRefs } from 'pinia';
import { useConnectionMessage } from '@/composables/useConnectionMessage';
import { useHandleConnectionData } from '@/composables/useHandleConnectionData';
import TrashTabsView from '../components/organisms/TrashTabsView.vue';
import BaseInput from '@/components/atoms/BaseInput.vue';
import ServiceStep from '@/components/molecules/ServiceStep.vue';
import serviceListJson from '../../public/mock/service_list.json';
import caseProgressJson from '../../public/mock/case_progress.json';
import type { User } from '@/stores/user';
import DialogModalVue from '../components/DialogModal.vue';
import MapView from '../components/organisms/MapView.vue';
import { start } from 'repl';

const loading = ref(false);

const props = defineProps({
  modelValue: Boolean,
  content: String,
  title: String,
  type: String
});

const showDialog = ref(false);
const dialogContent = ref('');
const dialogTitle = ref('');
const chatMsgValue = ref('');
const catlogType = ref('');

const store = useFormStore();

store.reset();

const userStore = useUserStore();

const { user } = storeToRefs(userStore);

const handleUserInfo = (event: { data: string }) => {
  const result: { name: string; data: User } = JSON.parse(event.data);

  user.value = result.data;
};

useConnectionMessage('userinfo', null);

useHandleConnectionData(handleUserInfo);

const route = useRoute();

const activeTab = ref(0);

if (route.query.isSearch) {
  activeTab.value = 1;
}

const serviceList = ref(serviceListJson);

const flatServiceList = computed(() =>
  serviceList.value.data
    .map((item) => item.agency)
    .reduce((prev, acc) => [...acc, ...prev], [])
    .map((item) => item.options)
    .reduce((prev, acc) => [...acc, ...prev], [])
);

const expandList = ref<string[]>([]);
const expandListSet = computed(() => new Set(expandList.value.map((name) => name)));

const onExpandClick = (name: string) => {
  if (expandListSet.value.has(name)) {
    const index = expandList.value.findIndex((el) => el === name);
    expandList.value.splice(index, 1);
  } else {
    expandList.value.push(name);
  }
};

const searchResult = ref<
  {
    id: string;
    title: string;
    subtitle: string;
    type: string;
    agency_type: string;
  }[]
>();

const searchResultTypeSet = computed(() => new Set(searchResult.value?.map((item) => item.type)));
const searchResultAgencyTypeSet = computed(
  () => new Set(searchResult.value?.map((item) => item.agency_type))
);
const searchResultTitle = computed(() => searchResult.value?.map((item) => item.title));

const onClick = (type: string) => {
  showDialog.value = !showDialog.value;
  catlogType.value = type;
};

const onSearchClick = () => {
  loading.value = !loading.value; // 顯示加載中
  fetch('https://lapras-backend-752705272074.asia-east1.run.app/api/chat/text/send', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ msg: chatMsgValue.value })
  })
    .then((res) => res.json())
    .then((data) => {
      // searchResult.value = data;
      showDialog.value = !showDialog.value;
      dialogContent.value = data;
      dialogTitle.value = chatMsgValue.value;
      catlogType.value = '';
      loading.value = !loading.value; // 顯示加載中
    });
};

// 定義響應式數據
const photo = ref(null); // 存儲照片的 Base64
const stream = ref(null); // 存儲攝像頭的流
const video = ref(null); // 引用 video 元素
const isCamera = ref(false); // 是否啟動攝像頭
const isFrontCamera = ref(false); // 記錄當前是否為前置攝像頭
const isPhotoPreview = ref(false); // 是否顯示照片預覽

// 啟動攝像頭
const startCamera = (facingMode = 'environment') => {
  isCamera.value = !isCamera.value;
  navigator.mediaDevices
    .getUserMedia({
      video: { facingMode: facingMode } // 使用前置或後置攝像頭
    })
    .then((mediaStream) => {
      stream.value = mediaStream;
      video.value.srcObject = mediaStream;
    })
    .catch((err) => {
      console.error('攝像頭啟動失敗:', err);
    });
};

// 停止攝像頭流
const stopCamera = () => {
  isCamera.value = !isCamera.value;
  if (stream.value) {
    stream.value.getTracks().forEach((track) => {
      track.stop();
    });
    stream.value = null; // 清除流
  }
};

// 切換前置與後置攝像頭
const switchCamera = () => {
  isFrontCamera.value = !isFrontCamera.value; // 切換前後攝像頭狀態

  stopCamera(); // 先停止當前攝像頭流

  // 重新啟動攝像頭，根據 isFrontCamera 選擇前置或後置
  startCamera(isFrontCamera.value ? 'user' : 'environment');
};

function dataURLToBlob(dataURL) {
  // 把 base64 的 dataURL 轉換成二進制格式的 Blob
  const byteString = atob(dataURL.split(',')[1]);
  const mimeString = dataURL.split(',')[0].split(':')[1].split(';')[0];

  const ab = new ArrayBuffer(byteString.length);
  const ia = new Uint8Array(ab);

  for (let i = 0; i < byteString.length; i++) {
    ia[i] = byteString.charCodeAt(i);
  }

  return new Blob([ab], { type: mimeString });
}

// 拍照功能
const capturePhoto = () => {
  const canvas = document.createElement('canvas');
  canvas.width = video.value.videoWidth;
  canvas.height = video.value.videoHeight;
  const ctx = canvas.getContext('2d');
  ctx.drawImage(video.value, 0, 0, canvas.width, canvas.height);

  // 將照片轉換為 base64 編碼
  const dataURL = canvas.toDataURL('image/png'); // 生成 dataURL
  photo.value = dataURL; // 存儲照片

  isPhotoPreview.value = true; // 顯示照片預覽
  stopCamera(); // 停止相機流
};

// 確認上傳照片
const confirmPhoto = async () => {
  const blob = dataURLToBlob(photo.value);

  // 創建 FormData 並附加圖片文件
  const formData = new FormData();
  formData.append('image', blob, 'image.png');
  isPhotoPreview.value = false; // 關閉照片預覽
  loading.value = !loading.value; // 顯示加載中

  try {
    const [response1, response2] = await Promise.all([
      fetch('https://lapras-backend-752705272074.asia-east1.run.app/api/chat/photo/upload', {
        method: 'POST',
        body: formData
      }),
      fetch('https://lapras-backend-752705272074.asia-east1.run.app/api/chat/photo/upload/thing', {
        method: 'POST',
        body: formData
      })
    ]);

    // 處理第一個回應
    const data1 = await response1.json();
    // 處理第二個回應
    const data2 = await response2.json();

    // 假設 API 回應格式包含 choices 並能取得內容，這裡使用第一個回應的資料
    showDialog.value = true;
    dialogContent.value = data1.choices[0].message.content;
    catlogType.value = '';

    // 如果需要處理第二個 API 回應的資料，可以在這裡進行
    dialogTitle.value = data2.choices[0].message.content;
  } catch (error) {
    console.error('上傳失敗:', error);
  } finally {
    loading.value = !loading.value; // 隱藏加載中
  }
};

// 重新拍攝照片
const retakePhoto = () => {
  isPhotoPreview.value = false; // 關閉照片預覽
  startCamera(isFrontCamera.value ? 'user' : 'environment');
};

// 在組件卸載前停止攝像頭流
onBeforeUnmount(() => {
  stopCamera();
});

// 定義 fileInput 的引用
const fileInput = ref(null);

// 觸發文件選擇
const triggerFileInput = () => {
  fileInput.value.click();
};

// 處理文件上傳
const handleFileUpload = (event) => {
  const file = event.target.files[0];
  if (file) {
    const formData = new FormData();
    formData.append('image', file); // 將文件附加到 FormData
    uploadImage(formData); // 調用上傳方法
  }
};

// 上傳圖片
const uploadImage = async (formData) => {
  loading.value = !loading.value; // 顯示加載中

  try {
    const [response1, response2] = await Promise.all([
      fetch('https://lapras-backend-752705272074.asia-east1.run.app/api/chat/photo/upload', {
        method: 'POST',
        body: formData
      }),
      fetch('https://lapras-backend-752705272074.asia-east1.run.app/api/chat/photo/upload/thing', {
        method: 'POST',
        body: formData
      })
    ]);

    // 處理第一個回應
    const data1 = await response1.json();
    // 處理第二個回應
    const data2 = await response2.json();

    // 假設 API 回應格式包含 choices 並能取得內容，這裡使用第一個回應的資料
    showDialog.value = true;
    dialogContent.value = data1.choices[0].message.content;
    catlogType.value = '';

    // 如果需要處理第二個 API 回應的資料，可以在這裡進行
    dialogTitle.value = data2.choices[0].message.content;
  } catch (error) {
    console.error('上傳失敗:', error);
  } finally {
    loading.value = !loading.value; // 隱藏加載中
  }
};

const selectedOption = ref('model-taipei');
const options = [
  { text: '台北垃圾分類模型', value: 'model-taipei' },
  { text: '台中垃圾分類模型', value: 'model-taichung' },
  { text: '東京垃圾分類模型', value: 'model-tokyo' }
];

const handleSelection = () => {
  console.log('已選擇：' + selectedOption.value);
};

const activeSituation = ref('apply');

const caseProgress = ref(caseProgressJson);

const applyRecord = computed(() =>
  caseProgress.value.data.filter((item) => item.current_step !== item.total_step)
);
const finishRecord = computed(() =>
  caseProgress.value.data.filter((item) => item.current_step === item.total_step)
);

const activeRecord = computed(() =>
  activeSituation.value === 'apply' ? applyRecord.value : finishRecord.value
);

/**
 * tab1 JS end
 */
</script>

<template>
  <template v-if="loading">
    <div style="background-color: #edf8fa; height: 100vh">
      <svg id="loader" viewBox="0 0 140 60" preserveAspectRatio="xMidYMid meet">
        <defs>
          <mask id="mask0" maskUnits="userSpaceOnUse">
            <rect class="line0" x="1" y="1" width="102" height="8" rx="4" ry="4" />
            <rect class="line1" x="15" y="11" width="70" height="8" rx="4" ry="4" />
            <rect class="line2" x="29" y="21" width="100" height="8" rx="4" ry="4" />
            <rect class="line3" x="29" y="31" width="66" height="8" rx="4" ry="4" />
            <rect class="line4" x="15" y="41" width="13" height="8" rx="4" ry="4" />
            <rect class="line5" x="1" y="51" width="13" height="8" rx="4" ry="4" />
          </mask>
          <mask id="mask1" maskUnits="userSpaceOnUse">
            <rect class="line0" x="1" y="1" width="102" height="8" rx="4" ry="4" />
            <rect class="line1" x="15" y="11" width="70" height="8" rx="4" ry="4" />
            <rect class="line2" x="29" y="21" width="100" height="8" rx="4" ry="4" />
            <rect class="line3" x="29" y="31" width="66" height="8" rx="4" ry="4" />
            <rect class="line4" x="15" y="41" width="13" height="8" rx="4" ry="4" />
            <rect class="line5" x="1" y="51" width="13" height="8" rx="4" ry="4" />
          </mask>

          <g id="group">
            <g class="line line0">
              <rect x="1" y="1" width="13" height="8" rx="4" ry="4" class="div" />
              <rect x="16" y="1" width="23" height="8" rx="4" ry="4" class="class-name" />
              <rect x="41" y="1" width="37" height="8" rx="4" ry="4" class="class" />
              <rect x="80" y="1" width="23" height="8" rx="4" ry="4" class="class" />
            </g>
            <g class="line line1">
              <rect x="15" y="11" width="13" height="8" rx="4" ry="4" class="div" />
              <rect x="30" y="11" width="23" height="8" rx="4" ry="4" class="class-name" />
              <rect x="55" y="11" width="30" height="8" rx="4" ry="4" class="class" />
            </g>
            <g class="line line2">
              <rect x="29" y="21" width="100" height="8" rx="4" ry="4" class="par" />
            </g>
            <g class="line line3">
              <rect x="29" y="31" width="66" height="8" rx="4" ry="4" class="par" />
            </g>
            <g class="line line4">
              <rect x="15" y="41" width="13" height="8" rx="4" ry="4" class="div" />
            </g>
            <g class="line line5">
              <rect x="1" y="51" width="13" height="8" rx="4" ry="4" class="div" />
            </g>
          </g>
        </defs>

        <g id="groups">
          <use xlink:href="#group" class="group group0" />
          <use xlink:href="#group" class="group group1" />
        </g>
      </svg>
    </div>
  </template>
  <template v-if="!loading">
    <main>
      <TrashTabsView v-model="activeTab">
        <template #tab0>
          <div class="py-4">
            <section class="flex items-center px-4">
              <BaseInput
                v-model="chatMsgValue"
                placeholder="您想要丟的垃圾是？"
                class="w-1/2"
              />
              <button class="search-button bg-div" @click="onSearchClick">
                <img src="@/assets/images/search-icon.svg" alt="搜尋" />
              </button>
              <div style="margin: 0px 5px">
                <label for="options">選擇模型：</label>
                <select
                  v-model="selectedOption"
                  @change="handleSelection"
                  style="border: solid 2px black; border-radius: 5px"
                >
                  <option v-for="option in options" :key="option.value" :value="option.value">
                    {{ option.text }}
                  </option>
                </select>
                <p>模型：{{ selectedOption }}</p>
              </div>
            </section>
            <div v-if="!isCamera && !isPhotoPreview" class="flex justify-center">
              <div
                class="w-11/12 mx-4 my-8 rounded-lg min-h-52 flex flex-col items-center justify-center cursor-pointer bg-div"
                @click="triggerFileInput"
              >
                <div class="flex justify-evenly items-center">
                  <div><i class="fa-solid fa-camera-retro text-8xl text-white py-4 select-none"></i></div>
                  <div><p class="py-4 select-none text-8xl text-white px-4">&</p></div>
                  <div><i class="fa-solid fa-cloud-arrow-up text-8xl text-white py-4 select-none"></i></div>
                </div>
                <p class="text-white text-center select-none">拍攝或上傳想要詢問的垃圾~</p>
              </div>
              <input
                type="file"
                ref="fileInput"
                style="display: none"
                @change="handleFileUpload"
                accept="image/*"
              />
              <!-- <div
                class="w-1/2 mx-4 my-8 rounded-lg min-h-52 flex flex-col items-center justify-center cursor-pointer bg-div"
                @click="startCamera"
              >
                <i class="fa-solid fa-camera-retro text-8xl text-white py-4 select-none"></i>
                <p class="text-white text-center select-none">拍攝想要詢問的垃圾~</p>
              </div> -->
            </div>
            <div
              v-if="isCamera && !isPhotoPreview"
              class="camera flex flex-col items-center justify-center m-2"
            >
              <div width="400" height="600" class="bg-black rounded-t-lg">
                <video ref="video" width="400" height="240" class="rounded-t-lg" autoplay></video>
              </div>
              <div class="rounded-b-lg flex bg-black justify-center" style="width: 400px">
                <button @click="stopCamera" class="text-white rounded-full p-4 m-1">
                  <i class="fa-solid fa-rectangle-xmark text-2xl select-none"></i>
                </button>
                <button @click="capturePhoto" class="text-white rounded-full p-4 m-1">
                  <i class="fa-solid fa-camera text-2xl select-none"></i>
                </button>
                <button @click="switchCamera" class="text-white rounded-full p-4 m-1">
                  <i class="fa-solid fa-arrows-rotate text-2xl select-none"></i>
                </button>
              </div>
            </div>
            <div v-if="isPhotoPreview" class="camera flex flex-col items-center justify-center m-2">
              <img
                :src="photo"
                alt="Captured Photo"
                width="400"
                height="240"
                class="rounded-t-lg"
              />
              <div class="rounded-b-lg flex bg-black justify-center" style="width: 400px">
                <button @click="confirmPhoto" class="text-white rounded-full p-4 m-1">
                  <i class="fa-solid fa-check text-2xl select-none"></i>
                </button>
                <button @click="retakePhoto" class="text-white rounded-full p-4 m-1">
                  <i class="fa-solid fa-xmark text-2xl select-none"></i>
                </button>
              </div>
            </div>
            <DialogModalVue
              v-model="showDialog"
              :content="dialogContent"
              :title="dialogTitle"
              :type="catlogType"
            ></DialogModalVue>
            <div
              v-if="!isCamera && !isPhotoPreview"
              class="camera flex flex-col items-center justify-center mx-4"
            >
              <hr class="w-full" />
              <h1 class="my-5 text-2xl font-black">垃圾分類介紹</h1>
              <div class="flex justify-evenly flex-wrap w-full">
                <div
                  class="w-5/12 my-4 rounded-lg h-16 flex items-center justify-center cursor-pointer bg-re-div"
                  @click="onClick('立體類')"
                >
                  立體類
                </div>
                <div
                  class="w-5/12 my-4 rounded-lg h-16 flex items-center justify-center cursor-pointer bg-re-div"
                  @click="onClick('平面類')"
                >
                  平面類
                </div>
                <div
                  class="w-5/12 my-4 rounded-lg h-16 flex items-center justify-center cursor-pointer bg-re-div"
                  @click="onClick('其他類')"
                >
                  其他類
                </div>
                <div
                  class="w-5/12 my-4 rounded-lg h-16 flex items-center justify-center cursor-pointer bg-re-div"
                  @click="onClick('一般垃圾')"
                >
                  一般垃圾
                </div>
              </div>
            </div>
          </div>
        </template>
        <template #tab1>
          <div class="p-4">
            <MapView />
          </div>
        </template>
      </TrashTabsView>
    </main>
  </template>
</template>

<style lang="postcss">
.search-button {
  @apply bg-primary-500 p-1 rounded-lg;
  @apply h-11 w-11;
  @apply flex justify-center items-center;
  @apply -translate-x-1;
}

.option-title {
  @apply relative;
  @apply before:content-[''];
  @apply before:w-1.5 before:h-0.5;
  @apply before:bg-primary-500;
  @apply before:inline-block;
  @apply before:absolute before:-left-3.5 before:top-1/2 before:-translate-y-1/2;
}

.situation-button {
  @apply text-primary-500;
  @apply first:rounded-l last:rounded-r;
  @apply border border-primary-500;
  @apply py-0.5;

  &--active {
    @apply bg-primary-500 text-white;
  }
}
</style>

<style lang="stylus">
/* colors of monokai: http://www.colourlovers.com/palette/1718713/Monokai */
grey = #272822 // sundried clay
orchid = #356C77 // pink
blue = #356C77 // bounded rationality
green = #93D4DF // henn1nk
orange = #356C77 // pumpkin spice

classColour = #FFE792
parColour = #272822

// How long a single loop (two blocks scrolling past) takes
animation_length = 2s

group_delay = animation_length / 2
line_delay = animation_length / 20
scroll_shift = 0 - animation_length / 8


:root
body
  height: 100%
  width: 100%
  overflow: hidden

body
  background-color: white

svg#loader
  height: 100%
  width: 100%

  mask
    > rect
      fill: white
      transform: translateX(-100%)
      animation: animation_length ease-in expand infinite

    for group_num in (0..1)
      &#mask{group_num}
        for line_num in (0..5)
          > rect.line{line_num}
            animation-delay: (line_num * line_delay + group_num * group_delay)

  #group
    > g.line
      > rect
        &.div
          fill: orchid
        &.class-name
          fill: green
        &.class
          fill: classColour
        &.par
          fill: parColour

  use.group
    animation: animation_length linear scroll infinite

    for group_num in (0..2)
      &.group{group_num}
        mask: url('#mask' + group_num)
        transform: translateY(group_num * 100%)
        animation-delay: (group_num * group_delay + scroll_shift)

@keyframes expand
  0%
  70.001%
    transform: scaleX(0) translateX(-10px)
  20%
  70%
    transform: scaleX(1) translateX(0)

@keyframes scroll
  0%
    transform: translateY(100%)
  100%
    transform: translateY(-100%)
</style>

<style>
.bg-re-div {
  border: 3px solid #468d9b;
  font-size: 16px;
  font-weight: bold;
  color: #468d9b;
}

.bg-re-div:hover {
  background-color: #f8e3bc;
}

.bg-div {
  background-color: #5ab4c5;
}

.bg-div:hover {
  background-color: #468d9b;
}
</style>
