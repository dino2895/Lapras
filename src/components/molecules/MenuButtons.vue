<template>
  <div class="absolute top-4 right-4 z-10 flex flex-col space-y-4">
    <button
      @click="$emit('toggle-menu')"
      class="w-20 custom-blue text-white px-6 py-3 rounded-full shadow-lg hover:bg-blue-300 transition-all duration-300"
    >
      選單
    </button>
    <button
      @click="$emit('reset-center')"
      class="bg-white text-white w-12 h-12 rounded-full shadow-lg hover:custom-gray transition-all duration-300 ml-auto"
      style="display: block"
    >
      <img src="@/assets/images/gps.png" class="w-6 h-6 mx-auto" />
    </button>
  </div>
</template>
  
  <script>
export default {
  name: 'MenuButtons',
  emits: ['toggle-menu', 'reset-center']
};
</script>
