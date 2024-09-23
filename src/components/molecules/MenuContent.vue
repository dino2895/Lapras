<template>
  <transition name="slide">
    <div
      v-show="showMenu"
      class="absolute top-16 left-1/2 transform -translate-x-1/2 bg-white shadow-lg rounded-lg z-20 p-6 w-80 text-center"
    >
      <button @click="$emit('toggle-menu')" class="style1">
        <img src="@/assets/images/cancel-icon.svg" />
      </button>
      <h3 class="text-lg font-bold mb-4">選單</h3>

      <div class="list-container">
        <p style="padding: 5px">點擊想要顯示的圖示</p>
        <button
          @click="toggleLayer('dogpoo')"
          class="custom-dog text-white w-full py-3 rounded-full mb-4 shadow hover:bg-blue-300 transition-all duration-300"
        >
          狗便清潔箱
        </button>
        <button
          @click="toggleLayer('cleanbox')"
          class="custom-blue text-white w-full py-3 rounded-full mb-4 shadow hover:bg-blue-300 transition-all duration-300"
        >
          行人專用清潔箱
        </button>
        <button
          @click="$emit('toggle-all-trashcar-layers-visibility')"
          class="custom-car text-white w-full py-3 rounded-full shadow hover:bg-blue-300 transition-all duration-300"
        >
          垃圾車站點
        </button>
      </div>
      <div class="list-other-container">
        <button
          @click="$emit('reset-center')"
          class="custom-heavygray text-white px-6 py-3 w-full rounded-full shadow-lg hover:bg-blue-300 transition-all duration-300"
        >
          回到目前定位
        </button>
        <button
          @click="$emit('toggle-navigation')"
          class="custom-heavygray text-white px-6 py-3 rounded-full shadow-lg hover:bg-blue-300 transition-all duration-300"
        >
          導航模式
        </button>
        <button
          @click="$emit('toggle-sidebar')"
          class="custom-heavygray text-white px-6 py-3 rounded-full shadow-lg hover:bg-blue-300 transition-all duration-300"
        >
          鬧鐘列表
        </button>
      </div>
    </div>
  </transition>
</template>
  
  <script>
export default {
  name: 'MenuContent',
  props: ['showMenu'],
  emits: [
    'toggle-menu',
    'toggle-layer-visibility',
    'toggle-all-trashcar-layers-visibility',
    'reset-center',
    'toggle-navigation',
    'toggle-sidebar'
  ],
  methods: {
    toggleLayer(layerId) {
      this.$emit('toggle-layer-visibility', layerId);
      this.$emit('toggle-menu');
    }
  }
};
</script>

<style>
.style1 {
  display: flex;
  justify-content: flex-start;
}

.custom-blue {
  background-color: #5ab4c5;
  /* 自定義藍色背景 */
}

.custom-gray {
  background-color: #d9d9d9;
  /* 自定義輝色背景 */
}

.custom-heavygray {
  background-color: #1e1d1d62;
  /* 自定義輝色背景 */
}

.custom-dog {
  background-color: #5e6a58;
  /* 自定義淺色背景 */
}

.custom-car {
  background-color: #a77f48;
  /* 自定義淺色背景 */
}
.list-container {
  display: flex;
  flex-direction: column;
  gap: 6px;
  border: solid 5px rgb(132, 196, 230);
  border-radius: 10px 10px 10px 10px;
  padding: 10px;
  margin-bottom: 10px;
}

.list-other-container {
  display: flex;
  flex-direction: column;
  gap: 16px;
  border: solid 5px rgb(255, 255, 255);
  border-radius: 10px 10px 10px 10px;
  padding: 10px;
}
</style>
