/*
    BIN to PHC takes a binary file, result of an Assembly program, and puts it in a PHC file format.

    The result PHC contains a bootloader in BASIC that will jump to the binary, allowing the
    usage of CLOAD on the PHC-25 computer.

    The binary code must have its entry point at &HC009.

    Technique described by Etno on RPUfOS Discord server.
*/

#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#ifndef min
#define min(a, b) ((a) < (b) ? (a) : (b))
#endif

const int MAX_NAME_LENGTH = 6;

const char header[] = {0xa5, 0xa5, 0xa5, 0xa5, 0xa5, 0xa5, 0xa5, 0xa5, 0xa5, 0xa5};

const char basic_code[] = {
        // CALL &HC009
        0xa5, 0x26, 0x48, 0x43, 0x30, 0x30, 0x39, 0x00};

const char footer[] = {
        // Pointer and number of the BASIC line code in memory
        0x00, 0x00, 0x01, 0xc0, 0x0a, 0x00, 0x00, 0xff, 0xff, 0xff, 0xff,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};

/* Get file size while keeping the file offset. */
int get_file_size(int file)
{
    off_t current = lseek(file, 0, SEEK_CUR);
    if (current == (off_t) -1)
    {
        perror("Error getting current file offset");
        return -1;
    }
    off_t size = lseek(file, 0, SEEK_END);
    if (size == (off_t) -1)
    {
        perror("Error seeking to end of file");
        return -1;
    }
    if (lseek(file, current, SEEK_SET) == (off_t) -1)
    {
        perror("Error restoring file offset");
        return -1;
    }
    return size;
}

typedef struct
{
    int input_file;
    int output_file;
    unsigned char* output_buffer;
} Context;

Context ctx = {0};

void clean_context()
{
    if (ctx.output_buffer)
    {
        free(ctx.output_buffer);
        ctx.output_buffer = NULL;
    }
    if (ctx.input_file >= 0)
    {
        close(ctx.input_file);
        ctx.input_file = -1;
    }
    if (ctx.output_file >= 0)
    {
        close(ctx.output_file);
        ctx.output_file = -1;
    }
}

int open_files(const char* input_file, const char* output_file)
{
    ctx.input_file = open(input_file, O_RDONLY);
    if (ctx.input_file < 0)
    {
        perror("Error opening input file");
        return -1;
    }

    ctx.output_file = open(output_file, O_WRONLY | O_CREAT | O_TRUNC, 0644);
    if (ctx.output_file < 0)
    {
        perror("Error opening output file");
        ctx.input_file = -1;
        return -1;
    }

    return 0;
}

int main(int argc, char* argv[])
{
    if (argc != 4)
    {
        printf("Usage: %s <phc_name> <input.bin> <output.phc>\n", argv[0]);
        return 1;
    }

    if (open_files(argv[2], argv[3]) < 0)
    {
        clean_context();
        return -1;
    }

    int input_size = get_file_size(ctx.input_file);
    if (input_size < 0)
    {
        clean_context();
        return 1;
    }

    char name[MAX_NAME_LENGTH + 1];
    memcpy(name, "      ", MAX_NAME_LENGTH); // Initialize with spaces
    memcpy(name, argv[1],
           min(strlen(argv[1]), MAX_NAME_LENGTH)); // memcpy because we don't want the \0

    int total_size =
            sizeof(header) + MAX_NAME_LENGTH + sizeof(basic_code) + input_size + sizeof(footer);
    ctx.output_buffer = calloc(total_size, sizeof(unsigned char));

    if (!ctx.output_buffer)
    {
        perror("Error allocating memory for output buffer");
        clean_context();
        return 1;
    }

    // Fill the output buffer
    int buffer_offset = 0;
    memcpy(ctx.output_buffer + buffer_offset, header, sizeof(header));
    buffer_offset += sizeof(header);
    memcpy(ctx.output_buffer + buffer_offset, name, MAX_NAME_LENGTH);
    buffer_offset += MAX_NAME_LENGTH;
    memcpy(ctx.output_buffer + buffer_offset, basic_code, sizeof(basic_code));
    buffer_offset += sizeof(basic_code);

    // Read the binary content from the input file
    size_t bytesRead = read(ctx.input_file, ctx.output_buffer + buffer_offset, input_size);
    if (bytesRead < 0)
    {
        perror("Error reading input file");
        clean_context();
        return 1;
    }
    buffer_offset += bytesRead;
    memcpy(ctx.output_buffer + buffer_offset, footer, sizeof(footer));
    buffer_offset += sizeof(footer);

    // Write the output buffer to the output file
    size_t bytesWritten = write(ctx.output_file, ctx.output_buffer, total_size);
    if (bytesWritten < 0)
    {
        perror("Error writing to output file");
        clean_context();
        return 1;
    }

    clean_context();

    return 0;
}
