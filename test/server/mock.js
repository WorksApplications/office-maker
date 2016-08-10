var users = [
  {
    id: 'admin01',
    pass: 'admin01',//TODO encrypt
    personId: 'admin01',
    role: 'admin'
  },
  {
    id: 'user01',
    pass: 'user01',//TODO encrypt
    personId: 'user01',
    role: 'general'
  }
];
var people = [
  {
    id:'admin01',
    org: 'Sample Co.,Ltd',
    name: 'Admin01',
    mail: 'admin01@xxx.com',
    image: 'images/users/admin01.png'
  },
  {
    id:'user01',
    org: 'Sample Co.,Ltd',
    name: 'User01',
    tel: '33510'
  }
];
var gridSize = 8;
var backgroundColors = [
  "#eda", "#baf", "#fba", "#9bd", "#af8", "#8df", "#bbb", "#fff", "rgba(255,255,255,0.5)"
];
var colors = [
  "#875", "#75a", "#c57", "#69a", "#8c5", "#5ab", "#666", "#000"
];
var prototypes = [
  { id: "1", color: "#8bd", name: "", width : gridSize*7, height: gridSize*12 }
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
  users: users,
  people: people,
  colors: allColors,
  prototypes: prototypes
};
