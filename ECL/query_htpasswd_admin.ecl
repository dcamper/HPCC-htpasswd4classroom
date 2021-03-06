IMPORT Std;
IMPORT * FROM LanguageExtensions;

#WORKUNIT('name', 'htpasswd_pws');
#OPTION('obfuscateOutput', TRUE);

//-----------------------------------------------------------------------------
// This code should be published as an hthor query
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// Constants to change for your environment
//-----------------------------------------------------------------------------

// The secret value someone must enter on the query form in order to successfully
// modify the user file; can be empty but, if it is, anyone will be able to make
// changes and that is probably a Bad Thing
SECRET_VALUE := 'Secret123';

// The full path to the htpasswd binary application
HTPASSWD_BIN := '/usr/bin/htpasswd';

// The full path to the htpasswd user file; this must match the file entered in
// the HPCC Systems configmgr configuration screen
HTPASSWD_FILE_PATH := '/etc/HPCCSystems/.htpasswd';

//-----------------------------------------------------------------------------

CMD_SET := 'set';
CMD_DELETE := 'delete';
CMD_LIST := 'list';

//-----------------------------------------------------------------------------
// Parameters
//
//      admin_secret        The secret value set by the SECRET_VALUE constant;
//                          value submitted must match constant exactly in order
//                          for the query to succeed
//      action              One of 'set' (create or update user/pw), 'delete'
//                          (delete user and pw), or 'list' (show users and
//                          their encrypted passwords)
//      username            The username to create/update/delete; can be a
//                          comma-delimited list of usernames, in which case
//                          the action will be applied to all of them
//      password            The password for the user designated by username;
//                          must not be empty; required only if action is 'set'
//                          and you want to set a specific password; if a non-
//                          empty string is submitted and multiple usernames
//                          are also provided, then the users will all acquire
//                          the same password; if no password is provided and
//                          the action is 'set' then a random password will
//                           be chosen for each username
//      verify_password     Repeat of the value in password field, if a value
//                          was provided
//
// Sample curl call when this is installed as an hthor query:
//
//      curl 'localhost:8002/WsEcl/submit/query/hthor/htpasswd_pws/json?admin_secret=Secret123&action=set&username=user1&password=MyNewPassword&verify_password=MyNewPassword'
//-----------------------------------------------------------------------------

#IF(SECRET_VALUE != '')
    STRING  _secret := '' : STORED('admin_secret', FORMAT(SEQUENCE(500), PASSWORD));
#END

STRING      _action := '' : STORED('action', FORMAT(SEQUENCE(1000), SELECT('*' + CMD_SET, CMD_DELETE, CMD_LIST)));

STRING      _username := '' : STORED('username', FORMAT(SEQUENCE(1000)));
STRING      _password := '' : STORED('password', FORMAT(SEQUENCE(1100), PASSWORD));
STRING      _password_verify := '' : STORED('verify_password', FORMAT(SEQUENCE(1200), PASSWORD));

#IF(SECRET_VALUE != '')
    secret := TRIM(_secret, ALL);
#END
username := Std.Str.ToLowerCase(TRIM(_username, ALL));
usernameList := Std.Str.SplitWords(username, ',');
password := TRIM(_password, ALL);
passwordVerify := TRIM(_password_verify, ALL);

needsUsername := (_action NOT IN [CMD_LIST]);
needsPassword := (password != '' OR passwordVerify != '');

//-----------------------------------------------------------------------------

// Validation checks

executionEngine := Std.Str.ToLowerCase(Std.System.Job.Platform());
IF(executionEngine != 'hthor', FAIL('This code must be run on hthor'));

#IF(SECRET_VALUE != '')
    IF(secret != SECRET_VALUE, FAIL('Bad secret'));
#END

IF(needsUsername AND username = '', FAIL('Username is required'));

IF(needsPassword AND password != passwordVerify, FAIL('Password entries do not match'));

//-----------------------------------------------------------------------------

FinalResultLayout := RECORD
    STRING      result__html;
END;

PWLayout := RECORD
    STRING      pw;
END;

PipeResultLayout := RECORD
    BOOLEAN     failed := FALSE;
END;

//-------------------------------------

STRING FileContents() := FUNCTION
    ds1 := DATASET
        (
            DYNAMIC(Std.File.ExternalLogicalFileName('127.0.0.1', HTPASSWD_FILE_PATH)),
            {STRING s},
            CSV(SEPARATOR('')),
            OPT
        );

    ds2 := PROJECT
        (
            ds1,
            TRANSFORM
                (
                    RECORDOF(LEFT),
                    SELF.s := LEFT.s + '<br/>'
                )
        );

    ds3 := ROLLUP
        (
            ds2,
            TRUE,
            TRANSFORM
                (
                    RECORDOF(LEFT),
                    SELF.s := LEFT.s + RIGHT.s
                )
        );

    RETURN ds3[1].s;
END;

//-------------------------------------

GeneratedPasswords(UNSIGNED2 numPasswords) := FUNCTION
    punctuationSet := ['!', '@', '#', '$', '%', '^', '&', '*', '-', '+', '='];
    RandomPunctuation() := punctuationSet[(RANDOM() % COUNT(punctuationSet)) + 1];

    // Naughty words sourced from https://github.com/LDNOOBW/naughty-words-js
    // Some of these words a most certainly not in the dictionary file, but it's
    // better to include them anyway; squeamish people should skip this text block
    naughtyWordList :=
        [
            'acrotomophilia', 'anal', 'anilingus', 'anus', 'apeshit', 'arsehole', 'ass',
            'asshole', 'assmunch', 'autoerotic', 'babeland', 'bangbros', 'bangbus', 'bareback',
            'barenaked', 'bastard', 'bastardo', 'bastinado', 'bbw', 'bdsm', 'beaner', 'beaners',
            'beastiality', 'bestiality', 'bimbos', 'birdlock', 'bitch', 'bitches', 'blowjob',
            'blumpkin', 'bollocks', 'bondage', 'boner', 'boob', 'boobs', 'bukkake', 'bulldyke',
            'bullshit', 'bunghole', 'busty', 'butt', 'buttcheeks', 'butthole', 'camgirl', 'camslut',
            'camwhore', 'carpetmuncher', 'cialis', 'circlejerk', 'clit', 'clitoris', 'clusterfuck', 'cock',
            'cocks', 'coprolagnia', 'coprophilia', 'cornhole', 'coon', 'coons', 'creampie', 'cum',
            'cumming', 'cumshot', 'cumshots', 'cunnilingus', 'cunt', 'darkie', 'daterape', 'deepthroat',
            'dendrophilia', 'dick', 'dildo', 'dingleberry', 'dingleberries', 'doggiestyle', 'doggystyle',
            'dolcett', 'domination', 'dominatrix', 'dommes', 'dvda', 'ecchi', 'ejaculation', 'erotic',
            'erotism', 'escort', 'eunuch', 'fag', 'faggot', 'fecal', 'felch', 'fellatio', 'feltch',
            'femdom', 'figging', 'fingerbang', 'fingering', 'fisting', 'footjob', 'frotting', 'fuck',
            'fuckin', 'fucking', 'fucktards', 'fudgepacker', 'futanari', 'gangbang', 'genitals', 'goatcx',
            'goatse', 'gokkun', 'goodpoop', 'goregasm', 'grope', 'g-spot', 'guro', 'handjob', 'hardcore',
            'hentai', 'homoerotic', 'honkey', 'hooker', 'horny', 'humping', 'incest', 'intercourse', 'jailbait',
            'jigaboo', 'jiggaboo', 'jiggerboo', 'jizz', 'juggs', 'kike', 'kinbaku', 'kinkster', 'kinky',
            'knobbing', 'livesex', 'lolita', 'lovemaking', 'masturbate', 'masturbating', 'masturbation', 'milf',
            'mong', 'motherfucker', 'muffdiving', 'nambla', 'nawashi', 'negro', 'neonazi', 'nigga', 'nigger',
            'nimphomania', 'nipple', 'nipples', 'nsfw', 'nude', 'nudity', 'nutten', 'nympho', 'nymphomania',
            'octopussy', 'omorashi', 'orgasm', 'orgy', 'paedophile', 'paki', 'panties', 'panty', 'pedobear',
            'pedophile', 'pegging', 'penis', 'pikey', 'pissing', 'pisspig', 'playboy', 'ponyplay', 'poof',
            'poon', 'poontang', 'punany', 'poopchute', 'porn', 'porno', 'pornography', 'pthc', 'pubes', 'pussy',
            'queaf', 'queef', 'quim', 'raghead', 'rape', 'raping', 'rapist', 'rectum', 'rimjob', 'rimming',
            'sadism', 'santorum', 'scat', 'schlong', 'scissoring', 'semen', 'sex', 'sexcam', 'sexo', 'sexy',
            'sexual', 'sexually', 'sexuality', 'shemale', 'shibari', 'shit', 'shitblimp', 'shitty', 'shota',
            'shrimping', 'skeet', 'slanteye', 'slut', 's&m', 'smut', 'snatch', 'snowballing', 'sodomize', 'sodomy',
            'spastic', 'spic', 'splooge', 'spooge', 'spunk', 'strapon', 'strappado', 'suck', 'sucks', 'swastika',
            'swinger', 'threesome', 'throating', 'thumbzilla', 'tit', 'tits', 'titties', 'titty', 'topless',
            'tosser', 'towelhead', 'tranny', 'tribadism', 'tubgirl', 'tushy', 'twat', 'twink', 'twinkie',
            'undressing', 'upskirt', 'urophilia', 'vagina', 'viagra', 'vibrator', 'vorarephilia', 'voyeur', 'voyeurweb',
            'voyuer', 'vulva', 'wank', 'wetback', 'whore', 'worldsex', 'xx', 'xxx', 'yaoi', 'yiffy', 'zoophilia'
        ];

    dictionaryWords := DATASET
        (
            Std.File.ExternalLogicalFileName('127.0.0.1', '/usr/share/dict/words'),
            {STRING word},
            CSV(QUOTE(''), SEPARATOR(''))
        );

    filteredWords1 := dictionaryWords(REGEXFIND('^[a-z]+$', word)); // only lowercase words
    filteredWords2 := filteredWords1(LENGTH(word) BETWEEN 3 and 6); // length limitation
    filteredWords := filteredWords2(word NOT IN naughtyWordList);   // not in our naughty list

    assignedWords1 := SORT
        (
            PROJECT
                (
                    NOFOLD(filteredWords),
                    TRANSFORM
                        (
                            {
                                UNSIGNED4   n,
                                RECORDOF(LEFT)
                            },
                            SELF.n := RANDOM(),
                            SELF := LEFT
                        )
                ),
            n
        );
    assignedWords2 := SORT
        (
            PROJECT
                (
                    NOFOLD(filteredWords),
                    TRANSFORM
                        (
                            {
                                UNSIGNED4   n,
                                RECORDOF(LEFT)
                            },
                            SELF.n := RANDOM(),
                            SELF := LEFT
                        )
                ),
            n
        );

    fullRes := COMBINE
        (
            assignedWords1,
            assignedWords2,
            TRANSFORM
                (
                    PWLayout,
                    SELF.pw := LEFT.word + RandomPunctuation() + RIGHT.word
                )
        );

    RETURN CHOOSEN(fullRes, numPasswords);
END;

//-------------------------------------

DoesFileExist() := Std.File.FileExists(Std.File.ExternalLogicalFileName('127.0.0.1', HTPASSWD_FILE_PATH));

//-------------------------------------

BOOLEAN CreateNewPassword(STRING username, STRING userPW) := FUNCTION
    optionalSetCmdOptions := IF(NOT DoesFileExist(), '-c ', ' ');

    // htpasswd -b [-c] file_path username password
    pipeRes := PIPE
        (
            HTPASSWD_BIN + ' -b ' + optionalSetCmdOptions + HTPASSWD_FILE_PATH + ' ' + username + ' ' + userPW,
            PipeResultLayout,
            CSV
        );

    PipeResultLayout FailXForm() := TRANSFORM
        SELF.failed := TRUE;
    END;

    res := CATCH(pipeRes, ONFAIL(FailXForm()));

    RETURN NOT res[1].failed;
END;

//-------------------------------------

BOOLEAN DeleteUser(STRING username) := FUNCTION
    // htpassword -D file_path username
    pipeRes := PIPE
        (
            HTPASSWD_BIN + ' -D ' + HTPASSWD_FILE_PATH + ' ' + username,
            PipeResultLayout,
            CSV
        );

    PipeResultLayout FailXForm() := TRANSFORM
        SELF.failed := TRUE;
    END;

    res := CATCH(pipeRes, ONFAIL(FailXForm()));

    RETURN NOT res[1].failed;
END;

//-----------------------------------------------------------------------------

ApplyUpdatePW(SET OF STRING usernames, STRING staticPW = '') := FUNCTION
    newPasswords := GeneratedPasswords(COUNT(usernames));
    givenPasswords := DATASET(COUNT(usernames), TRANSFORM(PWLayout, SELF.pw := staticPW));
    pwList := IF(staticPW = '', newPasswords, givenPasswords);
    res := COMBINE
        (
            DATASET(usernames, {STRING username}),
            pwList,
            TRANSFORM
                (
                    FinalResultLayout,
                    actionRes := CreateNewPassword(LEFT.username, RIGHT.pw);
                    pwReveal := IF(staticPW = '', RIGHT.pw, 'SUCCEEDED');
                    SELF.result__html := 'Create/update ' + LEFT.username + ':' + IF(actionRes, pwReveal, 'FAILED')
                )
        );

    RETURN res;
END;

//-------------------------------------

ApplyDelete(SET OF STRING usernames) := FUNCTION
    res := PROJECT
        (
            DATASET(usernames, {STRING username}),
            TRANSFORM
                (
                    FinalResultLayout,
                    actionRes := DeleteUser(LEFT.username);
                    SELF.result__html := 'Delete ' + LEFT.username + ':' + IF(actionRes, 'SUCCEEDED', 'FAILED')
                )
        );

    RETURN res;
END;

CollectList() := FUNCTION
    text := '<pre>' + FileContents() + '</pre>';
    RETURN DATASET([text], FinalResultLayout);
END;

//-----------------------------------------------------------------------------

// Execute action
CASE
    (_action,
        CMD_SET     =>  OUTPUT(ApplyUpdatePW(usernameList, password), NAMED('update')),
        CMD_DELETE  =>  OUTPUT(ApplyDelete(usernameList), NAMED('delete')),
        CMD_LIST    =>  OUTPUT(CollectList(), NAMED('list')),
        FAIL('Unknown action')
    );
