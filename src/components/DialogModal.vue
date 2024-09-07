<template>
  <transition name="modal" @after-leave="afterLeave">
    <dialog
      ref="modal"
      class="modal-container"
      v-show="innerModelValue"
      @click="handleClickOutSide"
    >
      <div class="footer">
        <slot>
          <button class="btn btn_border" @click="innerModelValue = false">CLOSE</button>
        </slot>
      </div>
      <div v-if="type === ''">
        <div class="header">
          <slot name="header">{{ title }}</slot>
        </div>

        <div class="body">
          <slot style="width: 70%;"> 類別：{{ content }} </slot>
        </div>

        <hr style="border: 2px solid black; margin: 10px 0;" />

        <p style="margin: 5px 0 10px 0">
          <strong>回收日期：</strong>{{ recyclingDate.join('、') }}
        </p>
        <ul style="margin: 10px 20px">
          <li v-for="item in contentFilteredItems" :key="item.name">
            <h3>
              <strong>{{ item.name }}</strong> : {{ item.replace }}
            </h3>
          </li>
        </ul>
      </div>
      <div v-if="type != ''">
        <div class="header">
          <slot name="header">{{ type }}</slot>
        </div>

        <div class="body">
          <!-- 顯示回收日期 -->
          <p style="margin: 5px 0 10px 0">
            <strong>回收日期：</strong>{{ recyclingDates.join('、') }}
          </p>
          <hr style="border: 2px solid black" />
          <h2
            style="
              font-weight: bold;
              text-transform: uppercase;
              font-size: 20px;
              margin: 10px 0 15px 0;
            "
          >
            回收物項目列表
          </h2>
          <ul style="margin: 10px 20px">
            <li v-for="item in filteredItems" :key="item.name">
              <h3>
                <strong>{{ item.name }}</strong> : {{ item.replace }}
              </h3>
            </li>
          </ul>
        </div>
      </div>
    </dialog>
  </transition>
</template>

<script>
import { ref, computed, onMounted, watch } from 'vue';
import trashData from '../lib/trash.json';

export default {
  props: {
    modelValue: Boolean,
    content: String,
    title: String,
    type: String // 用來篩選的類型
  },
  setup(props, ctx) {
    const modal = ref();

    const innerModelValue = computed({
      get: () => props.modelValue,
      set: (value) => ctx.emit('update:model-value', value)
    });

    const displayModal = (show) => {
      if (!modal.value) return;
      if (show) {
        modal.value.showModal();
      } else {
        modal.value.close();
      }
    };

    onMounted(() => {
      if (innerModelValue.value) displayModal(true);
    });

    watch(innerModelValue, (isOpen) => {
      if (isOpen) displayModal(true);
    });

    // 當 type 為空時，根據 content 進行篩選
    const contentFilteredItems = computed(() => {
      const category = trashData.categories.find((category) => category.type === props.content);
      return category ? category.items : [];
    });

    const recyclingDate = computed(() => {
      const category = trashData.categories.find((category) => category.type === props.content);
      return category ? category.recycling_dates : [];
    });

    // 篩選對應的項目資料
    const filteredItems = computed(() => {
      const category = trashData.categories.find((category) => category.type === props.type);
      return category ? category.items : [];
    });

    // 篩選對應的回收日期
    const recyclingDates = computed(() => {
      const category = trashData.categories.find((category) => category.type === props.type);
      return category ? category.recycling_dates : [];
    });

    const afterLeave = () => displayModal(false);

    const handleClickOutSide = ({ clientX: x, clientY: y }) => {
      if (!modal.value) return;

      const { left, right, top, bottom } = modal.value.getBoundingClientRect();
      if (x < left || x > right || y < top || y > bottom) innerModelValue.value = false;
    };

    return {
      modal,
      afterLeave,
      displayModal,
      innerModelValue,
      handleClickOutSide,
      filteredItems, // 回收項目
      recyclingDates, // 回收日期
      contentFilteredItems, // 根據 content 篩選的項目
      recyclingDate // 根據 content 篩選的回收日期
    };
  }
};
</script>

<style scoped>
ul {
  list-style-position: inside;
  padding-left: 0; /* 去除左邊預設的內距 */
}

li {
  list-style: disc;
  margin: 10px 0;
}

h3 {
  display: inline;
}

.modal-enter-from,
.modal-leave-to {
  opacity: 0;
}

.modal-enter-active {
  transition-timing-function: 'ease-out';
}

.modal-leave-active {
  transition-timing-function: 'ease-in';
}

.modal-enter-active,
.modal-leave-active {
  transition-duration: 200ms;
}

.modal-enter-from.modal-container,
.modal-leave-to.modal-container {
  transform: scale(0.9) translateY(-2rem);
}

.modal-container::backdrop {
  background-color: rgba(0, 0, 0, 0.5);
}

.modal-container {
  display: flex;
  flex-direction: column;
  gap: 16px;
  width: 90%;
  height: 600px;
  margin: auto;
  max-width: 800px;
  border-radius: 10px;
  padding: 20px;
  background-color: #f8e3bc;
  border: none;
}

.header {
  font-weight: bold;
  text-transform: uppercase;
  font-size: 20px;
  margin: 5px 0 15px 0;
  width: 70%;
}

.body {
  font-size: 16px;
}

.footer {
  position: absolute;
  top: 20px;
  right: 20px;
}

.btn {
  width: fit-content;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 16px;
  padding: 6px;
}

.btn:hover{
  background-color: rgb(0, 0, 0);
  color: rgb(242, 235, 193);
}

.title {
  font-size: 24px;
}

.btn_border {
  color: #f5ba4b;
  font-weight: bold;
  border: solid 3px #f5ba4b;
  border-radius: 10px;
  /* background-color: #f0c87c; */
  padding-left: 10px;
  padding-right: 10px;
}

.btn_border:hover {
  background-color: #f5ba4b;
  color: #f8e3bc;
}
</style>

