<template>
  <transition name="slide">
    <div v-show="showMenu" class="menu-container">
      <button @click="toggleMenu" class="style1">
        <img src="@/assets/images/cancel-icon.svg" />
      </button>
      <h1 class="menu-title">選單</h1>
      <div class="list-container">
        <div class="container">
          <label class="switch">
            <input type="checkbox" v-model="dogPooVisible" @change="toggleLayer('dogpoo')" />
            <span class="slider">
              <span class="title">狗便清潔箱</span>
              <span class="ball">
                <span class="icon">
                  <path
                    stroke="currentColor"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M8 18V6l8 6-8 6Z"
                  ></path>
                </span>
              </span>
            </span>
          </label>
        </div>

        <div class="container">
          <label class="switch">
            <input type="checkbox" v-model="cleanBoxVisible" @change="toggleLayer('cleanbox')" />
            <span class="slider">
              <span class="title">行人清潔箱</span>
              <span class="ball">
                <span class="icon">
                  <path
                    stroke="currentColor"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M8 18V6l8 6-8 6Z"
                  ></path>
                </span>
              </span>
            </span>
          </label>
        </div>

        <div class="container">
          <label class="switch">
            <input type="checkbox" v-model="TrashCarVisible" @change="toggleAllTrashcarLayers" />
            <span class="slider">
              <span class="title">垃圾車站點</span>
              <span class="ball">
                <span class="icon">
                  <path
                    stroke="currentColor"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M8 18V6l8 6-8 6Z"
                  ></path>
                </span>
              </span>
            </span>
          </label>
        </div>
      </div>
      <div class="list-other-container">
        <button @click="toggleNavigation" class="custom-button custom-heavygray">導航模式</button>
        <button @click="toggleSidebar" class="custom-button custom-heavygray">鬧鐘列表</button>
      </div>
    </div>
  </transition>
</template>

<script>
export default {
  name: 'MenuContent',
  props: ['showMenu', 'mapInstance'],
  emits: [
    'update:showMenu',
    'toggle-layer-visibility',
    'toggle-all-trashcar-layers-visibility',
    'reset-center',
    'toggle-navigation',
    'toggle-sidebar'
  ],
  data() {
    return {
      dogPooVisible: false,
      cleanBoxVisible: false,
      TrashCarVisible: false
    };
  },
  methods: {
    toggleMenu() {
      this.$emit('update:showMenu', !this.showMenu);
    },
    toggleLayer(layerId) {
      this.$emit('toggle-layer-visibility', layerId);
      //this.toggleMenu();
    },
    toggleAllTrashcarLayers() {
      this.$emit('toggle-all-trashcar-layers-visibility');
      //this.toggleMenu();
    },
    toggleNavigation() {
      this.$emit('toggle-navigation');
      this.toggleMenu();
    },
    toggleSidebar() {
      this.$emit('toggle-sidebar');
      this.toggleMenu();
    }
  }
};
</script>

<style>
.menu-container {
  position: absolute;
  top: 16px;
  left: 50%;
  transform: translateX(-50%);
  background: white;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
  border-radius: 8px;
  padding: 1rem;
  width: 20rem;
  z-index: 20;
}

.menu-title {
    text-align: center;
    font-weight: bold;
    margin-bottom: 1rem;
    font-size: 1.8rem;
    color: #333; /* 深灰色字體 */
    letter-spacing: 0.05em; /* 增加字母間距 */
    text-transform: uppercase; /* 字母轉換為大寫 */
    text-shadow: 1px 1px 3px rgba(0, 0, 0, 0.2); /* 添加輕微陰影 */
    border-bottom: 2px solid #ccc; /* 下方加上細邊框 */
    padding-bottom: 0.5rem; /* 邊框與字體之間距離 */
}

.info-text {
  text-align: center;
  padding: 5px;
}

.custom-button {
  width: 70%;
  margin: auto;
  padding: 0.75rem;
  border-radius: 0.375rem;
  margin-bottom: 0.5rem;
  font-size: 1rem;
  font-weight: 600;
  font-family: Arial, Helvetica, sans-serif;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
  transition: background-color 10s;
}

.custom-button:hover {
    transform: scale(1.05); /* 滑過時放大一點 */
}

.custom-blue {
  background-color: #5ab4c5;
  color: white;
}

.custom-car {
  background-color: #a77f48;
  color: white;
}
.custom-heavygray {
  background-color: rgba(30, 29, 29, 0.62);
  color: white;
}

.list-container,
.list-other-container {
  display: flex;
  flex-direction: column;
  gap: 6px;
  border-radius: 10px;
  padding: 10px;
}

/* From Uiverse.io by Na3ar-17 */
.container {
  display: flex;
  justify-content: center;
  align-items: center;
  margin: 0;
  padding: 0;
  box-sizing: border-box;
  font-family: Arial, Helvetica, sans-serif;
  color: #fff;
}

.switch {
  align-items: center;
  margin-bottom: 20px;
  font-size: 0.875rem;
  position: relative;
  display: inline-block;
  width: 12em;
  height: 3.5em;
}

.switch input {
  display: none;
  opacity: 0;
  width: 0;
  height: 0;
}

.switch input:checked + .slider .ball {
  box-shadow: 10px 10px 100px #7f8996;
}

.switch input:checked + .slider .title {
  left: 40%;
}

.switch input:checked + .slider {
  background-color: #22474E;
}

.switch input:focus + .slider {
  box-shadow: 10px 10px 100px #7f8996;
}

.switch input:checked + .slider .ball {
  left: 72%;
  transform: rotate(360deg);
  box-shadow: none;
}

.switch .slider {
  position: absolute;
  cursor: pointer;
  top: 0;
  left: -7%;
  right: 0;
  bottom: 0;
  background-color: #5AB4C5;
  transition: all 0.4s;
  border-radius: 30px;
  height: 3.5rem;
  width: 12rem;
}

.switch .slider .title {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  font-weight: 600;
  font-size: 1rem;
  transition: all 0.4s;
  -webkit-user-select: none;
  -ms-user-select: none;
  user-select: none;
}

.switch .slider .ball {
  background-color: #F1F3F4;
  height: 40px;
  width: 40px;
  border-radius: 50%;
  position: absolute;
  left: 3px;
  transition: 0.4s;
  top: 16%;
}

.switch .slider .ball .icon {
  position: absolute;
  left: 53%;
  transform: translate(-50%, -50%);
  color: #a4a6e9;
  font-size: 16px; /* 擴大圖標 */
}
.title::after {
  opacity: 0;
}
</style>
