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
    });
};

// 定義響應式數據
const photo = ref(null); // 存儲照片的 Base64
const stream = ref(null); // 存儲攝像頭的流
const video = ref(null); // 引用 video 元素

// 啟動攝像頭
const startCamera = () => {
  navigator.mediaDevices
    .getUserMedia({ video: true })
    .then((mediaStream) => {
      stream.value = mediaStream;
      video.value.srcObject = mediaStream;
    })
    .catch((err) => {
      console.error('攝像頭啟動失敗:', err);
    });
};

// 拍照功能
const capturePhoto = () => {
  const canvas = document.createElement('canvas');
  canvas.width = video.value.videoWidth;
  canvas.height = video.value.videoHeight;
  const ctx = canvas.getContext('2d');
  ctx.drawImage(video.value, 0, 0, canvas.width, canvas.height);

  // 將照片轉換為 base64 編碼
  photo.value = canvas.toDataURL('image/png');
};

// 在組件掛載時啟動攝像頭
onMounted(() => {
  startCamera();
});

// 在組件卸載前停止攝像頭流
onBeforeUnmount(() => {
  if (stream.value) {
    stream.value.getTracks().forEach((track) => {
      track.stop();
    });
  }
});

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
  <main>
    <TrashTabsView v-model="activeTab">
      <template #tab0>
        <div class="py-4">
          <section class="flex items-center px-4">
            <BaseInput v-model="chatMsgValue" placeholder="您想要丟的垃圾是？" class="flex-grow" />
            <button class="search-button" @click="onSearchClick">
              <img src="@/assets/images/search-icon.svg" alt="搜尋" />
            </button>
          </section>
          <div class="flex justify-center">
            <div
              class="w-1/2 mx-4 my-8 rounded-lg min-h-52 flex flex-col items-center justify-center"
              style="background-color: #5ab4c5"
            >
              <i class="fa-solid fa-cloud-arrow-up text-8xl text-white py-4"></i>
              <p class="text-white text-center">想要詢問的垃圾分類圖片?</p>
            </div>
            <div
              class="w-1/2 mx-4 my-8 rounded-lg min-h-52 flex flex-col items-center justify-center"
              style="background-color: #5ab4c5"
              @click="capturePhoto"
            >
              <i class="fa-solid fa-camera-retro text-8xl text-white py-4"></i>
              <p class="text-white text-center">拍攝想要詢問的垃圾~</p>
            </div>
          </div>
          <div class="camera">
            <video ref="video" width="640" height="480" autoplay></video>
            <button @click="capturePhoto" class="bg-black text-white">拍照</button>
          </div>
          <DialogModalVue v-model="showDialog" :content="dialogContent"></DialogModalVue>
          <!-- <p class="text-grey-500 mt-4 mb-2 px-4">請選擇要申請的項目</p>
          <ul v-show="!isSearch || (isSearch && searchResult?.length)">
            <li
              v-show="!searchResult?.length || searchResultTypeSet.has(item.name)"
              v-for="item in serviceList.data"
              :key="item.name"
              class="px-4 py-2"
              :class="{
                'bg-grey-50': expandListSet.has(item.name)
              }"
            >
              <button
                class="w-full flex justify-between items-center mb-5"
                @click="onExpandClick(item.name)"
              >
                <div class="flex items-end">
                  <img v-if="item.icon" :src="item.icon" class="w-5 h-5 object-cover mr-1" />
                  <span>{{ item.name }}</span>
                </div>
                <img
                  src="@/assets/images/down-icon.svg"
                  class="transition-transform"
                  :class="{
                    'rotate-180': expandListSet.has(item.name)
                  }"
                />
              </button>
              <div
                class="grid grid-rows-[0fr] transition-all"
                :class="{
                  'grid-rows-[1fr]': expandListSet.has(item.name)
                }"
              >
                <ul class="overflow-hidden">
                  <li
                    v-show="!searchResult?.length || searchResultAgencyTypeSet.has(agency.name)"
                    v-for="agency in item.agency"
                    :key="agency.name"
                  >
                    <div class="flex items-center mb-2">
                      <div class="w-2 h-2 rounded-full bg-primary-500 mr-3" />
                      <span class="text-primary-500 font-extrabold">
                        {{ agency.name }}
                      </span>
                    </div>
                    <div class="flex pl-[3px]">
                      <div class="w-0.5 bg-primary-500 mr-4 self-stretch"></div>
                      <ul>
                        <li
                          v-show="
                            !searchResult?.length ||
                            searchResultTitle?.filter((title) => title.includes(option.title))
                              .length
                          "
                          v-for="option in agency.options"
                          :key="option.id"
                          class="mb-3"
                        >
                          <RouterLink :to="{ name: 'form', params: { id: option.id } }">
                            <p class="option-title">{{ option.title }}</p>
                            <p v-if="option.subtitle" class="text-sm text-grey-400">
                              {{ option.subtitle }}
                            </p>
                          </RouterLink>
                        </li>
                      </ul>
                    </div>
                  </li>
                </ul>
              </div>
            </li>
          </ul>
          <div v-show="isSearch && !searchResult?.length" class="flex flex-col items-center pt-40">
            <p class="text-primary-500 font-bold">查無任何申辦相關項目</p>
          </div> -->
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