var gridSize = 8;
var backgroundColors = [
  "#eee", "#edb", "#bbf", "#fbb", "#abe", "#af9", "#9df", "#bbb", "#fff", "rgba(255,255,255,0.5)"
];
var colors = [
  "#875", "#75a", "#c57", "#69a", "#8c5", "#5ab", "#666", "#000"
];
var prototypes = [
  { id: "1",
    name: "",
    width : gridSize * 7,//70cm
    height: gridSize * 12,//120cm
    backgroundColor: "#eee",
    color: "#000",
    fontSize: 20,
    shape: 'rectangle'
  }, { id: "2",
    name: "",
    width : gridSize * 12,//120cm
    height: gridSize * 7,//70cm
    backgroundColor: "#eee",
    color: "#000",
    fontSize: 20,
    shape: 'rectangle'
  }
];
var allColors = backgroundColors.map((c, index) => {
  var id = index + '';
  var ord = index;
  return {
    id: id,
    ord: ord,
    type: 'backgroundColor',
    color: c
  };
}).concat(colors.map((c, index) => {
  var id = (backgroundColors.length + index) + '';
  var ord = (backgroundColors.length + index);
  return {
    id: id,
    ord: ord,
    type: 'color',
    color: c
  };
}));
module.exports = {
  colors: allColors,
  prototypes: prototypes
};
