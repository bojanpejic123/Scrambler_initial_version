#include "scrambler.hpp"
#include <tlm>
#include <tlm_utils/tlm_quantumkeeper.h>
using namespace sc_core;
using namespace sc_dt;
using namespace std;
using namespace tlm;

SC_HAS_PROCESS(scrambler);

scrambler::scrambler(sc_module_name name):
    sc_module(name),
    soc("soc"),
    period(200, SC_NS)
    {
        soc.register_b_transport(this, &scrambler::b_transport);
    }

void scrambler::b_transport(pl_t &pl, sc_time &offset)
{
    tlm_command cmd = pl.get_command();
    uint addr = pl.get_address();
    unsigned char *buf = pl.get_data_ptr();
    unsigned int len = pl.get_data_length();

    switch (cmd)
    {
        case TLM_WRITE_COMMAND:
            {

                end_of_block++;

                data = *((sc_uint<TOTAL_NUM_BIT_WIDTH> *) buf);
                channel_test[end_of_block] = data;

                pl.set_response_status(TLM_OK_RESPONSE);

                if (end_of_block == BLOCK_SIZE)
                {
                    end_of_block = 0;

                   	//Scrambling algorithm
                    int n = 0;
                    int x = 0;
                    for (int j = 1; j <= FIRST_BLOCK_DIVISION_SIZE; j++)
                    {
                        n = n + SECOND_BLOCK_DIVISION_SIZE;
                        x = x + FIRST_BLOCK_DIVISION_SIZE;
                        for (int q = n - SECOND_BLOCK_DIVISION_SIZE + 1; q <= n; q++)
                        {
                            channel_scrambled1[q] = channel_test[CHANNEL_BLOCK_SIZE - x + q];
                        }
                        int m = 0;
                        int y = 0;
                        for (int k = 1; k <= THIRD_BLOCK_DIVISION_SIZE; k++)
                        {
                            m = m + FIFTH_BLOCK_DIVISION_SIZE;
                            y = y + FOURTH_BLOCK_DIVISION_SIZE;
                            for (int w = 1 + n - SECOND_CHANNEL_BLOCK_DIVISION_SIZE + m; w <= 1 + n - (SECOND_BLOCK_DIVISION_SIZE + 1) + m; w++)
                            {
                                channel_scrambled[w] = channel_scrambled1[SECOND_CHANNEL_BLOCK_DIVISION_SIZE - y + w];
                            }
                        }
                    }

                    pl.set_response_status(TLM_OK_RESPONSE);
                }
               	//The end of scrambling algorithm
            }

            break;
        case TLM_READ_COMMAND:
            {

                memcpy(buf, &channel_scrambled[end_of_block_read], sizeof(channel_scrambled[end_of_block_read]));
                end_of_block_read++;

                if (end_of_block_read == BLOCK_SIZE + 1)
                {
                    end_of_block_read = 1;
                }

                pl.set_response_status(TLM_OK_RESPONSE);
                break;
            }
        default:
            {
                pl.set_response_status(TLM_ADDRESS_ERROR_RESPONSE);
                break;
            }
    }
    offset += sc_time(10, SC_NS);

}
