var gridSize = 8;
var backgroundColors = [
  "#eda", "#baf", "#fba", "#9bd", "#af8", "#8df", "#bbb", "#fff", "rgba(255,255,255,0.5)"
];
var colors = [
  "#875", "#75a", "#c57", "#69a", "#8c5", "#5ab", "#666", "#000"
];
var prototypes = [
  { id: "1",
    name: "",
    width : gridSize*7,//70cm
    height: gridSize*12,//120cm
    backgroundColor: "#eda",
    color: "#000",
    fontSize: 14,
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
