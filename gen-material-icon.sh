

target=("notification/priority_high")
s=''
for var in ${target[@]}
do
  category=`echo $var | cut -d'/' -f1`
  name=`echo $var | cut -d'/' -f2`
  url=https://raw.githubusercontent.com/google/material-design-icons/master/$category/svg/production/ic_${name}_24px.svg
  c=`curl -s $url | sed -e 's/.*path d="//' | sed -e 's/"\/><\/svg>//'`
  func="{-|-}\n${name} : Color -> Int -> Svg msg\n${name} =\n  icon \"${c}\"\n"
  s="${s}\r\n${func}"
done

echo -e $s >> src/elm/View/Icons.elm
