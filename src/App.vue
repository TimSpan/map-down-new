<!-- 高德2.0版本 -->

<script setup>
import hunan from './utils/hunan.json'
import { getAreaCode } from './utils/area.js'
import { onMounted, onUnmounted, reactive, ref } from 'vue'
const showLoading = ref(true)
const centerList = ref([])
let map = null
let currentJson = hunan
function up() {
  if (currentJson.name === hunan.name) {
    return
  }
  let fhcode = getAreaCode(currentJson.name)['codes'][0]
  console.log(fhcode)
  if (fhcode === '430000') {
    map.clearMap()
    currentJson = hunan
    initPolygon(hunan)
  } else {
    if (fhcode) {
      map.clearMap()
      const url = 'https://www.hndyjqrh.cn/api/multialarm/pic/download?creator=geo&file=' + fhcode + '.geojson'
      fetch(url)
        .then((response) => response.json())
        .then((data) => {
          currentJson = data
          initPolygon(data)
          map.setFitView()
        })
    }
  }
}

let renderMarker = function (item) {
  const { name = '', center = 0 } = item
  let marker = new AMap.Marker({
    content: `<div >${name}</div>`,
    anchor: 'center',
    draggable: false,
    cursor: 'pointer',
    position: center,
    extData: item,
    zIndex: 1000,
  })
  marker.setMap(map)
}

let marker2 = null
let renderMarker2 = function (item) {
  const { name, center } = item
  if (!marker2) {
    marker2 = new AMap.Marker({
      content: `
                <div class="tooltip" style="background-color: white;border: 1px solid #ccc;box-shadow: 0 0 10px rgba(0, 0, 0, 0.2);border-radius: 4px;padding: 8px;font-family: Arial, sans-serif; font-size: 14px;color: #333;">
                  <div class="tooltip-content">
                    <p style="margin: 0;line-height: 1.5;"><strong>name:</strong> <a style=" color: blue;text-decoration: none;" href="#">${name}</a></p>
                  </div>
                </div>
              `,
      anchor: 'bottom-left',
      draggable: false,
      cursor: 'pointer',
      position: center,
      zIndex: 1000,
    })
    map.add(marker2)
  }
}
const clearMarker = function () {
  if (marker2 !== null) {
    map.remove(marker2)
    marker2 = null
  }
}

const p_path = reactive({
  path: [],
})

let addPolygon = function (index) {
  let polygon = new AMap.Polygon({
    index: index,
    strokeWeight: 2,
    path: p_path.path,
    clickable: false,
    fillOpacity: 0.8,
    fillColor: '#FAFBFC',
    strokeWeight: 1,
    strokeColor: '#3A4659',
    lineJoin: 'round',
  })
  let polygon_mouseover = polygon.on('mouseover', () => {
    polygon.setOptions({
      fillOpacity: 0.8,
      fillColor: '#2681FF',
    })
    let arr = currentJson.features[polygon_mouseover._opts.index].geometry.coordinates[0][0]
    const highestLatitudePoint = arr.reduce((highest, current) => {
      return current[1] > highest[1] ? current : highest
    }, arr[0])
    let obj = {
      center: highestLatitudePoint,
      name: currentJson.features[polygon_mouseover._opts.index].properties.name,
    }
    renderMarker2(obj)
  })
  polygon.on('mouseout', () => {
    polygon.setOptions({
      fillOpacity: 0.8,
      fillColor: '#FAFBFC',
    })
    clearMarker()
  })
  polygon.on('mousedown', (e) => {
    console.log('currentJson_______________', currentJson)
    renderPolygon(e.target._opts.index)
  })
  map.add(polygon)
  map.setFitView()
}

const renderPolygon = (i) => {
  const path = []
  currentJson.features.forEach((item, index) => {
    if (i == index) {
      let code
      if (item.properties.hasOwnProperty('adcode')) {
        code = item.properties.adcode
      } else {
        if (item.properties.id.length === 5) {
          return
        } else {
          code = item.properties.id
        }
      }
      map.clearMap()
      const url = 'https://www.hndyjqrh.cn/api/multialarm/pic/download?creator=geo&file=' + code + '.geojson'
      fetch(url)
        .then((response) => response.json())
        .then((data) => {
          currentJson = data
          initPolygon(data)
        })
    }
  })
  p_path.path = path
  addPolygon(i)
}

function getCenter(arr) {
  let centerLonLat = []
  if (arr.length) {
    const lon = []
    const lat = []
    const poly = []
    for (let i = 0, len = arr.length; i < len; i++) {
      lon.push(arr[i][0])
      lat.push(arr[i][1])
    }
    for (let i = 0, len = lon.length; i < len; i++) {
      poly.push({
        x: parseFloat(lon[i]),
        y: parseFloat(lat[i]),
        z: 0,
      })
    }
    const sortedLongitudeArray = poly.map((item) => item.x).sort()
    const sortedLatitudeArray = poly.map((item) => item.y).sort()
    const centerLongitude = ((parseFloat(sortedLongitudeArray[0]) + parseFloat(sortedLongitudeArray[sortedLongitudeArray.length - 1])) / 2).toFixed(14)
    const centerLatitude = ((parseFloat(sortedLatitudeArray[0]) + parseFloat(sortedLatitudeArray[sortedLatitudeArray.length - 1])) / 2).toFixed(14)
    centerLonLat = [Number(centerLongitude), Number(centerLatitude)]
  }
  return centerLonLat
}

function initPolygon(data) {
  showLoading.value = true
  data.features.forEach((item, index) => {
    let center = getCenter(item.geometry.coordinates[0][0])
    centerList.value.push(center)
    const path = []
    item.geometry.coordinates[0][0].forEach((ele) => {
      path.push(new AMap.LngLat(ele[0], ele[1]))
    })
    p_path.path = path
    addPolygon(index)
  })
  map.setFitView()
  let timeID = setTimeout(() => {
    showLoading.value = false
    clearTimeout(timeID)
  }, 200)
}

onMounted(() => {
  map = new AMap.Map('container', {
    viewMode: '3D',
    zoom: 1,
    center: [113.801655, 27.870046],
  })
  initPolygon(hunan)
})

onUnmounted(() => {
  map?.destroy()
})
</script>

<template>
  <div id="container"></div>
  <button @click="up">行政区域上浮</button>
  <div v-if="showLoading" class="small-bg">
    <dv-loading>
      <div color-white>地图加载中...</div>
    </dv-loading>
  </div>
</template>

<style scoped>
#container {
  width: 100%;
  height: 800px;
  position: relative;
}

.small-bg {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  display: flex;
  justify-content: center;
  align-items: center;
  background-color: rgba(0, 0, 0, 0.5);
  z-index: 10; /* 确保在最上层 */
}
</style>
