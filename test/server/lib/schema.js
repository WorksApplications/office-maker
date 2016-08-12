
function userKeyValues(user) {
  return [
    ["id", user.id],
    ["pass", user.pass],
    ["role", user.role],
    ["personId", user.personId],
  ];
}
function personKeyValues(person) {
  return [
    ["id", person.id],
    ["empNo", person.empNo],
    ["name", person.name],
    ["org", person.org],
    ["tel", person.tel],
    ["mail", person.mail],
    ["image", person.image]
  ];
}
function floorKeyValues(tenantId, floor) {
  return [
    ["id", floor.id],
    ["version", floor.version],
    ["tenantId", tenantId],
    ["name", floor.name],
    ["ord", floor.ord],
    ["image", floor.image],
    ["width", floor.width],
    ["height", floor.height],
    ["realWidth", floor.realWidth],
    ["realHeight", floor.realHeight],
    ["public", floor.public],
    ["updateBy", floor.updateBy],
    ["updateAt", floor.updateAt]
  ];
}
function prototypeKeyValues(tenantId, proto) {
  return [
    ["id", proto.id],
    ["tenantId", tenantId],
    ["name", proto.name],
    ["width", proto.width],
    ["height", proto.height],
    ["backgroundColor", proto.backgroundColor],
    ["color", proto.color],
    ["fontSize", proto.fontSize],
    ["shape", proto.shape]
  ];
}

function objectKeyValues(floorId, floorVersion, object) {
  return [
    ["id", object.id],
    ["name", object.name],
    ["type", object.type],
    ["x", object.x],
    ["y", object.y],
    ["width", object.width],
    ["height", object.height],
    ["backgroundColor", object.backgroundColor],
    ["fontSize", object.fontSize],
    ["color", object.color],
    ["shape", object.shape],
    ["personId", object.personId],
    ["floorId", floorId],
    ["floorVersion", floorVersion],
    ["modifiedVersion", object.modifiedVersion]
  ];
}

function colorKeyValues(tenantId, c) {
  return [
    ["id", c.id],
    ["tenantId", tenantId],
    ["ord", c.ord],
    ["type", c.type],
    ["color", c.color]
  ];
}

module.exports = {
  userKeyValues: userKeyValues,
  personKeyValues: personKeyValues,
  floorKeyValues: floorKeyValues,
  prototypeKeyValues: prototypeKeyValues,
  objectKeyValues: objectKeyValues,
  colorKeyValues: colorKeyValues
};
