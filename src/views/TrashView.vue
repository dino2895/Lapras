<script setup lang="ts">
import { ref } from 'vue';
import TrashTabsView from '../components/organisms/TrashTabsView.vue';
import MapView from '../components/organisms/MapView.vue';
const activeTab = ref(0);
<<<<<<< HEAD
=======

if (route.query.isSearch) {
  activeTab.value = 1;
}

const chatMsgValue = ref('');
const serviceList = ref(serviceListJson);
const isSearch = ref(false);

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
  fetch(`https://lapras-backend-752705272074.asia-east1.run.app` + '/api/chat/text/send', {
    method: 'POST',
    body: JSON.stringify({ msg: chatMsgValue.value })
  })
    .then((res) => res.json())
    .then((data) => {
      // searchResult.value = data;
      var result = document.getElementById('result');
      if (result) {
        result.innerHTML = `<h1>${data}</h1>`;
      }
      // isSearch.value = true;
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
>>>>>>> 99f48b5e945df01a535f8e569defc1bb7de14b4a
</script>

<template>
  <main>
    <TrashTabsView v-model="activeTab">
      <template #tab0>
        <div class="py-4">
<<<<<<< HEAD
          <p>這是 Tab 1 的內容。</p>
=======
          <section class="flex items-center px-4">
            <BaseInput v-model="chatMsgValue" placeholder="您想要丟的垃圾是？" class="flex-grow" />
            <button class="search-button" @click="onSearchClick">
              <img src="@/assets/images/search-icon.svg" alt="搜尋" />
            </button>
          </section>
          <div class="flex justify-center">
            <div class="w-1/2 mx-4 my-8 rounded-lg min-h-52 flex flex-col items-center justify-center" style="background-color: #5ab4c5">
              <i class="fa-solid fa-cloud-arrow-up text-8xl text-white py-4"></i>
              <p class="text-white text-center">想要詢問的垃圾分類圖片?</p>
            </div>
            <div class="w-1/2 mx-4 my-8 rounded-lg min-h-52 flex flex-col items-center justify-center" style="background-color: #5ab4c5">
              <i class="fa-solid fa-camera-retro text-8xl text-white py-4"></i>
              <p class="text-white text-center">請輸入您想要丟的垃圾</p>
            </div>
          </div>
          <div id="result"></div>
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
>>>>>>> 99f48b5e945df01a535f8e569defc1bb7de14b4a
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
/* 如果有需要樣式的話，可以在這裡加上 */
</style>
