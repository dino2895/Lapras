<template>
  <transition name="modal" @after-leave="afterLeave">
    <dialog
      ref="modal"
      class="modal-container"
      v-show="innerModelValue"
      @click="handleClickOutSide"
    >
      <div class="header">
        <slot name="header">{{ title }}類別為...</slot>
      </div>

      <div class="body">
        <slot>
            {{ content }}
        </slot>
      </div>

      <div class="footer">
        <slot>
          <button class="btn btn_border" @click="innerModelValue = false">CLOSE</button>
        </slot>
      </div>
    </dialog>
  </transition>
</template>

<script>
import { ref, computed, onMounted, watch } from 'vue';

export default {
  props: {
    modelValue: Boolean,
    content: String,
    title: String
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
      handleClickOutSide
    };
  }
};
</script>

<style scoped>
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
  width: 100%;
  height: 400px;
  margin: auto;
  max-width: 800px;
  border-radius: 10px;
  padding: 20px;
  background-color: antiquewhite;
  border: none;
}

.header {
  font-weight: bold;
  text-transform: uppercase;
}

.body {
  font-size: 16px;
}

.footer {
  margin-top: auto;
  display: flex;
  justify-content: flex-end;
}

.btn {
  width: fit-content;
  height: 50px;
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

.btn_border{
  border: solid 3px rgb(115, 115, 118);
  border-radius: 10px 10px 10px 10px;
  background-color: rgb(242, 235, 193);
  padding-left: 10px;
  padding-right: 10px;
}

</style>
