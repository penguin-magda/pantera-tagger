m4_include(`predicate.m4')

#define TAGSET (this->tagsets[Phase])

#define ISNULL(offset) (text[index + (offset)].chosen_tag[Phase] == Lexeme::tag_type::getNullTag())
#define POSNUM(offset) (text[index + (offset)].chosen_tag[Phase].getPos())
#define POS(offset) (TAGSET->getPartOfSpeech(POSNUM(offset)))
#define DEFPOS(name, offset) const PartOfSpeech* name = ISNULL(offset) ? NULL : POS(offset);

#define FORCAT(name, name_idx, offset) \
    BOOST_FOREACH(const Category* name, POS(offset)->getCategories()) { \
        int name_idx = TAGSET->getCategoryIndex(name);
#define NEXTCAT \
    }

#define VALUE(offset, cat_idx) \
    (text[index + offset].chosen_tag[Phase].getValue(cat_idx))

#define C(cat_num) \
    (p.params.categories[cat_num] == -1 ? "pos" : \
     TAGSET->getCategory(p.params.categories[cat_num])->getName().c_str())
#define P(p_num) \
     TAGSET->getPartOfSpeech(p.params.pos[p_num])->getName().c_str()
#define V(cat_num, v_num) \
    (p.params.categories[cat_num] == -1 ? \
     P(v_num) :\
     TAGSET->getCategory(p.params.categories[cat_num])->getValue( \
        p.params.values[v_num]).c_str())

m4_define(`NEARBY_CAT', `

PTEMPLATE_BEGIN(`Nearby'$1`CatPredicateTemplate', $1)

    PTEMPLATE_FIND_PREDICATES {
        if (ISNULL(0)) return;

        Predicate<Lexeme> p = Predicate<Lexeme>(this);
        p.params.pos[0] = POSNUM(0);
        PTEMPLATE_FOR_EACH_OFFSET(`
            DEFPOS(pos`'O, Offset);
        ')
        FORCAT(cat, c, 0) {
            p.params.categories[0] = c;
            p.params.values[0] = VALUE(0, c);
            PTEMPLATE_FOR_EACH_OFFSET(`
                if (pos`'O && pos`'O->hasCategory(cat)) {
                    p.params.values[1] = VALUE(Offset, c);
                    v.push_back(p);
                }
            ')
        } NEXTCAT

        p.params.categories[0] = -1;
        PTEMPLATE_FOR_EACH_OFFSET(`
            if (pos`'O) {
                p.params.pos[1] = POSNUM(Offset);
                v.push_back(p);
            }
        ')
    }

    PTEMPLATE_MATCH {
        if (p.params.pos[0] != POSNUM(0))
            return false;
        int c = p.params.categories[0];
        if (c == -1) {
            return (PTEMPLATE_FOR_EACH_OFFSET(`(!ISNULL(Offset) && p.params.pos[1] == POSNUM(Offset))', ||));
        } else {
            return (PTEMPLATE_FOR_EACH_OFFSET(`(!ISNULL(Offset) && p.params.values[1] == VALUE(Offset, c))', ||))
                    && p.params.values[0] == VALUE(0, c);
        }
    }

    PTEMPLATE_STRING_REPR(
        "(" PTEMPLATE_FOR_EACH_OFFSET(`"T[%d]|%s = %s"', `" OR "') ") AND T[0]|pos = %s AND T[0]|%s = %s",
            PTEMPLATE_FOR_EACH_OFFSET(`Offset, C(0), V(0, 1), ')
            P(0), C(0), V(0, 0))

    PTEMPLATE_USES_CATEGORY0(`yes')

PTEMPLATE_END

')

m4_define(`NEARBY_EXACT_CAT', `

PTEMPLATE_BEGIN(`NearbyExact'$1`CatPredicateTemplate', $1)

    PTEMPLATE_FIND_PREDICATES {
        Predicate<Lexeme> p = Predicate<Lexeme>(this);
        p.params.pos[0] = POSNUM(0);
        PTEMPLATE_FOR_EACH_OFFSET(`
            DEFPOS(pos`'O, Offset);
        ')
        FORCAT(cat, c, 0) {
            p.params.categories[0] = c;
            p.params.values[0] = VALUE(0, c);
            PTEMPLATE_FOR_EACH_OFFSET(`
                if (!(pos`'O && pos`'O->hasCategory(cat)))
                    continue;
            ')
            PTEMPLATE_FOR_EACH_OFFSET(`
                p.params.values[O] = VALUE(Offset, c);
            ')
            v.push_back(p);
        } NEXTCAT

        p.params.categories[0] = -1;
        PTEMPLATE_FOR_EACH_OFFSET(`
            if (!pos`'O)
                return;
            p.params.pos[O] = POSNUM(Offset);
            v.push_back(p);
        ')
    }

    PTEMPLATE_MATCH {
        if (p.params.pos[0] != POSNUM(0))
            return false;
        int c = p.params.categories[0];
        if (c == -1) {
            return (PTEMPLATE_FOR_EACH_OFFSET(`(!ISNULL(Offset) && p.params.pos[O] == POSNUM(Offset))', &&));
        } else {
            return (PTEMPLATE_FOR_EACH_OFFSET(`(!ISNULL(Offset) && p.params.values[O] == VALUE(Offset, c))', &&))
                    && p.params.values[0] == VALUE(0, c);
        }
    }

    PTEMPLATE_STRING_REPR(
        PTEMPLATE_FOR_EACH_OFFSET(`"T[%d]|%s = %s"', `" AND "') " AND T[0]|pos = %s AND T[0]|%s = %s",
            PTEMPLATE_FOR_EACH_OFFSET(`Offset, C(0), V(0, O), ')
            P(0), C(0), V(0, 0))

    PTEMPLATE_USES_CATEGORY0(`yes')

PTEMPLATE_END

')

NEARBY_CAT(`1')
NEARBY_CAT(`2')
NEARBY_CAT(`3')
NEARBY_EXACT_CAT(`1')
NEARBY_EXACT_CAT(`2')

template<class Lexeme, int Phase>
class CCaseCatPredicateTemplate : public PredicateTemplate<Lexeme>
{
public:
CCaseCatPredicateTemplate(const vector<const Tagset*> tagsets) : PredicateTemplate<Lexeme>(tagsets) { }

void findMatchingPredicates(vector<Predicate<Lexeme> >& v,
                                                      vector<Lexeme>& text,
                                                      int index) {

    if (text[index].getOrth()[0] >= 'A' && text[index].getOrth()[0] <= 'Z') {
        Predicate<Lexeme> p = Predicate<Lexeme>(this);
        p.params.tags[0] = text[index].chosen_tag[Phase];
        v.push_back(p);
    }
}
bool predicateMatches(const Predicate<Lexeme>& p,
            vector<Lexeme>& text, int index) {
    return (p.params.tags[0] == text[index].chosen_tag[Phase]
            && text[index].getOrth()[0] >= 'A' && text[index].getOrth()[0] <= 'Z');
}
string predicateAsString(const Predicate<Lexeme>& p) {

    char str[STR_SIZE];
    sprintf(str, "T[0] = %s AND ORTH[0] starts with capital letter", T(tags[0]));
    return string(str);
}
};

template<class Lexeme, int Phase>
class Prefix2CatPredicateTemplate : public PredicateTemplate<Lexeme>
{
public:
Prefix2CatPredicateTemplate(const vector<const Tagset*> tagsets) : PredicateTemplate<Lexeme>(tagsets) { }

void findMatchingPredicates(vector<Predicate<Lexeme> >& v,
                                                      vector<Lexeme>& text,
                                                      int index) {

    const string& orth = text[index].getOrth();
    int len = orth.length();
    if (len >= 2) {
        Predicate<Lexeme> p = Predicate<Lexeme>(this);
        p.params.tags[0] = text[index].chosen_tag[Phase];
        p.params.chars[0] = orth[0];
        p.params.chars[1] = orth[1];
        v.push_back(p);
    }
}
bool predicateMatches(const Predicate<Lexeme>& p,
            vector<Lexeme>& text, int index) {
    const string& orth = text[index].getOrth();
    int len = orth.length();
    return (len >= 2 && p.params.tags[0] == text[index].chosen_tag[Phase]
            && orth[0] == p.params.chars[0]
            && orth[1] == p.params.chars[1]);
}
string predicateAsString(const Predicate<Lexeme>& p) {

    char str[STR_SIZE];
    sprintf(str, "T[0] = %s AND ORTH starts with %c%c", T(tags[0]), p.params.chars[0], p.params.chars[1]);
    return string(str);
}
};

template<class Lexeme, int Phase>
class Suffix2CatPredicateTemplate : public PredicateTemplate<Lexeme>
{
public:
Suffix2CatPredicateTemplate(const vector<const Tagset*> tagsets) : PredicateTemplate<Lexeme>(tagsets) { }

void findMatchingPredicates(vector<Predicate<Lexeme> >& v,
                                                      vector<Lexeme>& text,
                                                      int index) {

    const string& orth = text[index].getOrth();
    int len = orth.length();
    if (len >= 2) {
        Predicate<Lexeme> p = Predicate<Lexeme>(this);
        p.params.tags[0] = text[index].chosen_tag[Phase];
        p.params.chars[0] = orth[len - 2];
        p.params.chars[1] = orth[len - 1];
        v.push_back(p);
    }
}
bool predicateMatches(const Predicate<Lexeme>& p,
            vector<Lexeme>& text, int index) {
    const string& orth = text[index].getOrth();
    int len = orth.length();
    return (len >= 2 && p.params.tags[0] == text[index].chosen_tag[Phase]
            && orth[len - 2] == p.params.chars[0]
            && orth[len - 1] == p.params.chars[1]);
}
string predicateAsString(const Predicate<Lexeme>& p) {

    char str[STR_SIZE];
    sprintf(str, "T[0] = %s AND ORTH ends with %c%c", T(tags[0]), p.params.chars[0], p.params.chars[1]);
    return string(str);
}
};



#undef TAGSET
#undef POS
#undef DEFPOS
#undef FORCAT
#undef NEXTCAT
#undef VALUE
#undef C
#undef V

m4_dnl vim:syntax=cpp