
template<class Lexeme, int Phase, int Offset>
class PartialNearbyTagPredicateTemplate : public PredicateTemplate<Lexeme>
{
public:
PartialNearbyTagPredicateTemplate(const vector<const Tagset*> tagsets) : PredicateTemplate<Lexeme>(tagsets) { }

void findMatchingPredicates(vector<Predicate<Lexeme> >& v,
                                                      vector<Lexeme>& text,
                                                      int index) {

    Predicate<Lexeme> p = Predicate<Lexeme>(this);
    p.params.tags[0] = text[index].chosen_tag[Phase];
    p.params.tags[1] = text[index + Offset].chosen_tag[Phase - 1];
    v.push_back(p);

}
bool predicateMatches(const Predicate<Lexeme>& p,
            vector<Lexeme>& text, int index) {
    return (p.params.tags[1] == text[index + Offset].chosen_tag[Phase - 1])
            && p.params.tags[0] == text[index].chosen_tag[Phase];
}
wstring predicateAsWString(const Predicate<Lexeme>& p) {
    char str[STR_SIZE];
    sprintf(str, "T[%d] = %s AND T[0] = %s", Offset, T(tags[1]), S(tags[0]));
    return ascii_to_wstring(str);
}
};


template<class Lexeme, int Phase, int Offset1, int Offset2>
class PartialNearby2TagsPredicateTemplate : public PredicateTemplate<Lexeme>
{
public:
PartialNearby2TagsPredicateTemplate(const vector<const Tagset*> tagsets) : PredicateTemplate<Lexeme>(tagsets) { }

void findMatchingPredicates(vector<Predicate<Lexeme> >& v,
                                                      vector<Lexeme>& text,
                                                      int index) {
    Predicate<Lexeme> p = Predicate<Lexeme>(this);
    p.params.tags[0] = text[index].chosen_tag[Phase];
    p.params.tags[1] = text[index + Offset1].chosen_tag[Phase - 1];
    v.push_back(p);
    

    if (text[index + Offset2].chosen_tag[Phase - 1] != text[index + Offset1].chosen_tag[Phase - 1]) {
        p.params.tags[1] = text[index + Offset2].chosen_tag[Phase - 1];
        v.push_back(p);
    }
}
bool predicateMatches(const Predicate<Lexeme>& p,
            vector<Lexeme>& text, int index) {
    return (p.params.tags[1] == text[index + Offset1].chosen_tag[Phase - 1] ||
            p.params.tags[1] == text[index + Offset2].chosen_tag[Phase - 1])
            && p.params.tags[0] == text[index].chosen_tag[Phase];
}
wstring predicateAsWString(const Predicate<Lexeme>& p) {
    char str[STR_SIZE];
    sprintf(str, "(T[%d] = %s OR T[%d] = %s) AND T[0] = %s", Offset1, T(tags[1]),
            Offset2, T(tags[1]), S(tags[0]));
    return ascii_to_wstring(str);
}
};

