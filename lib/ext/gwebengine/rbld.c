#include <ruby.h>
void load_rb(const char* pth, const char* data)
{
	ruby_init();
    ruby_init_loadpath();

	char* options[] = {"-V", "-eload File.expand_path(ARGV[0])", (char*) pth , (char*) data };
	void* node = ruby_options(3, options);

	int state;
	if (ruby_executable_node(node, &state))
	{
		state = ruby_exec_node(node);
	}

	if (state)
	{
		/* handle exception, perhaps */
		//printf("fail\n");
	}

	//ruby_cleanup(state);
}

