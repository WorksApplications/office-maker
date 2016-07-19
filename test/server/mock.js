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
var colors = ["#ed9", "#b9f", "#fa9", "#8bd", "#af6", "#6df"
, "#bbb", "#fff", "rgba(255,255,255,0.5)"];
var prototypes = [
  { id: "1", color: "#8bd", name: "", width : gridSize*7, height: gridSize*12 }
];
module.exports = {
  users: users,
  // floors: floors,
  people: people,
  colors: colors,
  prototypes: prototypes
};
