
function userKeyValues(user) {
  return [
    ["id", user.id],
    ["role", user.role],
    ["personId", user.personId],
  ];
}
function personKeyValues(person) {
  return [
    ["id", person.id],
    ["name", person.name],
    ["org", person.org],
    ["tel", person.tel],
    ["mail", person.mail],
    ["image", person.image]
  ];
}
function floorKeyValues(floor) {
  return [
    ["id", floor.id],
    ["version", 0],//TODO
    ["name", floor.name],
    ["image", floor.image],
    ["realWidth", floor.realWidth],
    ["realHeight", floor.realHeight],
    ["public", floor.public],
    ["publishedBy", floor.publishedBy],
    ["publishedAt", floor.publishedAt]
  ];
}
function prototypeKeyValues(proto) {
  return [
    ["id", proto.id],
    ["name", proto.name],
    ["width", proto.width],
    ["height", proto.height],
    ["color", proto.color]
  ];
}
function equipmentKeyValues(equipment) {
  return [
    ["id", equipment.id],
    ["name", equipment.name],
    ["width", equipment.width],
    ["height", equipment.height],
    ["color", equipment.color],
    ["personId", equipment.personId],
    ["floorId", equipment.floorId]
  ];
}

module.exports = {
  userKeyValues: userKeyValues,
  personKeyValues: personKeyValues,
  floorKeyValues: floorKeyValues,
  prototypeKeyValues: prototypeKeyValues,
  equipmentKeyValues: equipmentKeyValues
};
