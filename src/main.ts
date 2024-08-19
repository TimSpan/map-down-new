import { createApp } from 'vue'
import DataVVue3 from '@kjgl77/datav-vue3'
import App from './App.vue'

const app = createApp(App)
app.use(DataVVue3)
app.mount('#app')
