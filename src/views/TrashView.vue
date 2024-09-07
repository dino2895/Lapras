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
  content: String
});

const showDialog = ref(false);
const dialogContent = ref('');
const chatMsgValue = ref('');

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
const confirmPhoto = () => {
  const blob = dataURLToBlob(photo.value);

  // 創建 FormData 並附加圖片文件
  const formData = new FormData();
  formData.append('image', blob, 'image.png');
  isPhotoPreview.value = false; // 關閉照片預覽
  loading.value = !loading.value; // 顯示加載中

  fetch('https://lapras-backend-752705272074.asia-east1.run.app/api/chat/photo/upload', {
    method: 'POST',
    body: formData
  })
    .then((res) => res.json())
    .then((data) => {
      // searchResult.value = data;
      showDialog.value = true;
      dialogContent.value = data.choices[0].message.content;
      loading.value = !loading.value; // 顯示加載中
    })
    .catch((error) => {
      console.error('上傳失敗:', error);
      loading.value = !loading.value; // 顯示加載中
    });
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
const uploadImage = (formData) => {
  loading.value = !loading.value; // 顯示加載中

  fetch('https://lapras-backend-752705272074.asia-east1.run.app/api/chat/photo/upload', {
    method: 'POST',
    body: formData
  })
    .then((res) => res.json())
    .then((data) => {
      // searchResult.value = data;
      showDialog.value = !showDialog.value;
      dialogContent.value = data.choices[0].message.content;
      loading.value = !loading.value; // 顯示加載中
    })
    .catch((error) => {
      console.error('上傳失敗:', error);
      loading.value = !loading.value; // 顯示加載中
    });
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
    <div class="load">
      <div class="loading-cat">
        <div class="body"></div>
        <div class="head">
          <div class="face"></div>
        </div>
        <div class="foot">
          <div class="tummy-end"></div>
          <div class="bottom"></div>
          <div class="legs left"></div>
          <div class="legs right"></div>
        </div>
        <div class="hands left"></div>
        <div class="hands right"></div>
      </div>
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
                class="flex-grow"
              />
              <button class="search-button bg-div" @click="onSearchClick">
                <img src="@/assets/images/search-icon.svg" alt="搜尋" />
              </button>
            </section>
            <div v-if="!isCamera && !isPhotoPreview" class="flex justify-center">
              <div
                class="w-1/2 mx-4 my-8 rounded-lg min-h-52 flex flex-col items-center justify-center cursor-pointer bg-div"
                @click="triggerFileInput"
              >
                <i class="fa-solid fa-cloud-arrow-up text-8xl text-white py-4 select-none"></i>
                <p class="text-white text-center select-none">上傳想要詢問的垃圾~</p>
              </div>
              <input
                type="file"
                ref="fileInput"
                style="display: none"
                @change="handleFileUpload"
                accept="image/*"
              />
              <div
                class="w-1/2 mx-4 my-8 rounded-lg min-h-52 flex flex-col items-center justify-center cursor-pointer bg-div"
                @click="startCamera"
              >
                <i class="fa-solid fa-camera-retro text-8xl text-white py-4 select-none"></i>
                <p class="text-white text-center select-none">拍攝想要詢問的垃圾~</p>
              </div>
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
                <button @click="confirmPhoto" class="text-white rounded-full p-2 m-1">
                  <i class="fa-solid fa-check text-2xl select-none"></i>
                </button>
                <button @click="retakePhoto" class="text-white rounded-full p-2 m-1">
                  <i class="fa-solid fa-xmark text-2xl select-none"></i>
                </button>
              </div>
            </div>
            <DialogModalVue v-model="showDialog" :content="dialogContent"></DialogModalVue>
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

<style>
.bg-div {
  background-color: #5ab4c5;
}

.bg-div:hover {
  background-color: #468d9b;
}

:global(body) {
  margin: 0;
  height: 100%;
}

.load {
  padding: 180px 40px 0 40px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.loading-cat {
  position: relative;
  display: inline-block;
  width: 480px;
  height: 360px;
  animation: 2.74s linear infinite loading-cat;
}
.loading-cat .head,
.loading-cat .foot,
.loading-cat .body {
  position: absolute;
  top: 0;
  right: 0;
  bottom: 0;
  left: 0;
  margin: auto;
  border-radius: 50%;
  width: 240px;
  height: 240px;
}
.loading-cat .body {
  background-image: radial-gradient(
    transparent 0%,
    transparent 35%,
    #383c4b 35%,
    #383c4b 39%,
    #bca1d5 39%,
    #bca1d5 46%,
    #efe0fd 46%,
    #efe0fd 60%,
    #bca1d5 60%,
    #bca1d5 67%,
    #383c4b 67%,
    #383c4b 100%
  );
}
.loading-cat .head:before,
.loading-cat .foot:before {
  background-image: radial-gradient(
    transparent 0%,
    transparent 35%,
    #383c4b 35%,
    #383c4b 39%,
    #bca1d5 39%,
    #bca1d5 67%,
    #383c4b 67%,
    #383c4b 100%
  );
}
.loading-cat .head:before {
  content: '';
  width: 100%;
  height: 100%;
  position: absolute;
  border-radius: 50%;
  clip-path: polygon(100% 20%, 50% 50%, 70% -10%);
  -webkit-clip-path: polygon(100% 20%, 50% 50%, 70% -10%);
}
.loading-cat .head:after {
  content: '';
  width: 66px;
  height: 40px;
  position: absolute;
  top: 13px;
  right: 63px;
  background-image: linear-gradient(white 65%, transparent 65%),
    radial-gradient(white 51%, #383c4b 55%, #383c4b 68%, transparent 70%);
  transform: rotate(-66deg);
}
.loading-cat .head .face {
  width: 80px;
  height: 60px;
  left: 145px;
  top: 29px;
  position: absolute;
  transform: rotate(-47deg);
  background:
    radial-gradient(circle, #efe0fd 0%, #efe0fd 23%, transparent 23%) -3px 17px no-repeat,
    radial-gradient(circle, #383c4b 0%, #383c4b 6%, transparent 6%) 12px -12px no-repeat,
    radial-gradient(circle, #383c4b 0%, #383c4b 6%, transparent 6%) -12px -12px no-repeat,
    radial-gradient(#bca1d5 0%, #bca1d5 15%, transparent 15%) 0 -11px no-repeat,
    radial-gradient(circle, transparent 5%, #383c4b 5%, #383c4b 10%, transparent 10%) -3px -5px
      no-repeat,
    radial-gradient(circle, transparent 5%, #383c4b 5%, #383c4b 10%, transparent 10%) 3px -5px no-repeat,
    radial-gradient(circle, #bca1d5 45%, transparent 45%) 0 -3px,
    linear-gradient(
      transparent 35%,
      #383c4b 35%,
      #383c4b 41%,
      transparent 41%,
      transparent 44%,
      #383c4b 44%,
      #383c4b 50%,
      transparent 50%,
      transparent 53%,
      #383c4b 53%,
      #383c4b 59%,
      transparent 59%
    );
}
.loading-cat .foot:before,
.loading-cat .foot:after {
  content: '';
  width: 100%;
  height: 100%;
  position: absolute;
}
.loading-cat .foot:before {
  border-radius: 50%;
  clip-path: polygon(50% 50%, 0% 50%, 0% 25%);
  -webkit-clip-path: polygon(50% 50%, 0% 50%, 0% 25%);
}
.loading-cat .foot .tummy-end {
  width: 24px;
  height: 24px;
  position: absolute;
  border-radius: 50%;
  background-color: #efe0fd;
  left: 19px;
  top: 105px;
}
.loading-cat .foot .bottom {
  width: 35px;
  height: 15px;
  position: absolute;
  top: 78px;
  left: 12px;
  border: 6px solid #383c4b;
  border-bottom: 0;
  border-radius: 50%;
  transform: rotate(21deg);
  background: #bca1d5;
}
.loading-cat .hands,
.loading-cat .legs,
.loading-cat .foot:after {
  width: 10px;
  height: 25px;
  position: absolute;
  border: 6px solid #383c4b;
  background-color: #bca1d5;
}
.loading-cat .hands {
  border-top: 0;
  border-radius: 0 0 12px 12px;
}
.loading-cat .hands.left {
  top: 144px;
  right: 163px;
  transform: rotate(-20deg);
}
.loading-cat .hands.right {
  top: 123px;
  right: 128px;
  transform: rotate(-25deg);
}
.loading-cat .legs {
  border-bottom: 0;
  border-radius: 12px 12px 0 0;
}
.loading-cat .legs.left {
  top: 65px;
  left: 50px;
  transform: rotate(25deg);
}
.loading-cat .legs.right {
  top: 53px;
  left: 12px;
  transform: rotate(22deg);
}
.loading-cat .foot:after {
  width: 8px;
  height: 40px;
  top: 42px;
  left: 36px;
  z-index: -1;
  transform: rotate(25deg);
  background-color: #efe0fd;
  border-bottom: 0;
  border-radius: 12px 12px 0 0;
}
@keyframes body {
  0% {
    clip-path: polygon(50% 50%, 0% 50%, 0% 100%, 100% 100%, 100% 20%);
    -webkit-clip-path: polygon(50% 50%, 0% 50%, 0% 100%, 100% 100%, 100% 20%);
  }
  10% {
    clip-path: polygon(50% 50%, 30% 120%, 50% 100%, 100% 100%, 100% 20%);
    -webkit-clip-path: polygon(50% 50%, 30% 120%, 50% 100%, 100% 100%, 100% 20%);
  }
  20% {
    clip-path: polygon(50% 50%, 100% 90%, 120% 90%, 100% 100%, 100% 20%);
    -webkit-clip-path: polygon(50% 50%, 100% 90%, 120% 90%, 100% 100%, 100% 20%);
  }
  40% {
    clip-path: polygon(50% 50%, 100% 45%, 120% 45%, 120% 50%, 100% 20%);
    -webkit-clip-path: polygon(50% 50%, 100% 45%, 120% 45%, 120% 50%, 100% 20%);
  }
  50% {
    clip-path: polygon(50% 50%, 100% 45%, 120% 45%, 120% 50%, 100% 20%);
    -webkit-clip-path: polygon(50% 50%, 100% 45%, 120% 45%, 120% 50%, 100% 20%);
  }
  65% {
    clip-path: polygon(50% 50%, 100% 65%, 120% 65%, 120% 50%, 100% 20%);
    -webkit-clip-path: polygon(50% 50%, 100% 65%, 120% 65%, 120% 50%, 100% 20%);
  }
  80% {
    clip-path: polygon(50% 50%, 75% 130%, 120% 65%, 120% 50%, 100% 20%);
    -webkit-clip-path: polygon(50% 50%, 75% 130%, 120% 65%, 120% 50%, 100% 20%);
  }
  90% {
    clip-path: polygon(50% 50%, -20% 110%, 50% 120%, 100% 100%, 100% 20%);
    -webkit-clip-path: polygon(50% 50%, -20% 110%, 50% 120%, 100% 100%, 100% 20%);
  }
  100% {
    clip-path: polygon(50% 50%, 0% 50%, 0% 100%, 100% 100%, 100% 20%);
    -webkit-clip-path: polygon(50% 50%, 0% 50%, 0% 100%, 100% 100%, 100% 20%);
  }
}
@keyframes loading-cat {
  0% {
    transform: rotate(0deg);
  }
  10% {
    transform: rotate(-80deg);
  }
  20% {
    transform: rotate(-180deg);
  }
  40% {
    transform: rotate(-245deg);
  }
  50% {
    transform: rotate(-250deg);
  }
  68% {
    transform: rotate(-300deg);
  }
  90% {
    transform: rotate(-560deg);
  }
  100% {
    transform: rotate(-720deg);
  }
}
@keyframes foot {
  0% {
    transform: rotate(-10deg);
  }
  10% {
    transform: rotate(-100deg);
  }
  20% {
    transform: rotate(-145deg);
  }
  35% {
    transform: rotate(-190deg);
  }
  50% {
    transform: rotate(-195deg);
  }
  70% {
    transform: rotate(-165deg);
  }
  100% {
    transform: rotate(-10deg);
  }
}
.loading-cat .body {
  animation: 2.74s linear infinite body;
}
.loading-cat .foot {
  animation: 2.74s linear infinite foot;
}
</style>
