<script setup lang="ts">
import { ref } from 'vue';
import TrashTabsView from '../components/organisms/TrashTabsView.vue';
import MapView from '../components/organisms/MapView.vue';
const activeTab = ref(0);
</script>

<template>
  <main>
    <TrashTabsView v-model="activeTab">
      <template #tab0>
        <div class="py-4">
          <p>這是 Tab 1 的內容。</p>
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
