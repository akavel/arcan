#define COUNT_OF(x) \
	((sizeof(x)/sizeof(0[x])) / ((size_t)(!(sizeof(x) % sizeof(0[x])))))

enum launch_mode {
	LAUNCH_VT100 = 0,
	LAUNCH_TUI   = 1,
	LAUNCH_WL    = 2,
	LAUNCH_X11   = 3
};

struct ext_cmd {
	uint32_t id;
	int flags;
	char** argv;
	char** env;
	char* wd;
	enum launch_mode mode;
};

struct cli_state {
	char** env;
	char* cwd;
	enum launch_mode mode;

	uint32_t id_counter;
	struct ext_cmd pending[4];
	bool blocked;
	struct tui_cell* prompt;
	size_t prompt_sz;
};

struct cli_command {
	const char* name;
	struct ext_cmd* (*exec)(
		struct cli_state* state, char** argv, ssize_t* ofs, char** err);
};

/*
 * return the built-in CLI command matching (exec)
 */
struct cli_command* cli_get_builtin(const char* cmd);

/*
 * split up message into a dynamically allocated array of dynamic
 * strings according to the following rules:
 *
 * global-state:
 *  \ escapes next character
 *    ends argument
 *
 * group_tbl (string of possible group characters, e.g. "'`),
 *           ends with an empty group (.enter == 0)
 *
 * character in group_tbl begins and ends a nested expansion that
 * will be expanded according to the expand callback and the group.
 *
 * the returned string will be added to the resulting string table
 * verbatim.
 */
struct group_ent;
struct group_ent {
	char enter;
	char leave;
	bool leave_eol;
	char* (*expand)(struct group_ent*, const char*);
};

struct argv_parse_opt {
	size_t prepad;
	struct group_ent* groups;
	char sep;
};

char** extract_argv(const char* message,
	struct argv_parse_opt opts, ssize_t* err_ofs);
