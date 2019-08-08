#include "mixer.cpp"
#include "stubs.hpp"

using ethsnarks::ppT;
using ethsnarks::mixer_witness;

// TODO: change this when circuit inputs are changed
static const char *selftest_proof_inputs_json = "{\"root\":\"10997780549811400708601504250471468195534978745431599276492721316290896218338\",\"wallet_address\":\"742769056376932917098136869028921629509414507844\",\"nullifier\":\"4122865252528855556151764751710800669589320451792353049178187261023293512954\",\"nullifier_secret\":\"38013247834874329155180715878624481281276991464893709827868698396437084\",\"address\":0,\"path\":[\"19321998414906712342737093331922571923461328494325615870852140381009276079041\",\"17296471688945713021042054900108821045192859417413320566181654591511652308323\",\"4832852105446597958495745596582249246190817345027389430471458078394903639834\",\"15461585713781279680447535913361668280097097610604253131987810512856082142108\",\"3769229681213467802270422158523493430161857055705140649626474846487042015294\",\"13647072325998791786887512624449791092179176488816171646493984798290104596073\",\"15878703434308824340339618970594258057165374118672855332783394926709017260312\",\"9818535244623190070553351286595164824271849851242010032077443835159358157641\",\"7922042747482293668273191578664256926795518592713187716634465425744689501095\",\"2789379477568327439974616531924765517697226176694772607766179476825856863254\",\"1005990462954276647377962471017597558634496836612490083107674994677711544070\",\"11969127117470424354039737501297729117493728984899640368626242601139714409309\",\"5344394176735217860849296704604296419896817858372607211534789260173133864770\",\"14116139569958633576637617144876714429777518811711593939929091541932333542283\",\"15047636386088019397123018594201170501174366319805738014399908655923285748980\"]}";


int main( int argc, char **argv )
{
	if( argc < 3 ) {
		fprintf(stderr, "Usage: mixer_selftest <test.pk.raw> <test.vk.json> [test.proof.json [test.inputs.json]]\n");
		return 99;
	}

	const char *mixer_pk = argv[1];
	const char *mixer_vk = argv[2];

	ppT::init_public_params();

	const mixer_witness witness = mixer_witness::fromJSON(selftest_proof_inputs_json);

	// Generate & verify a proof, all in-memory
	std::cerr << "Setting up gadget" << std::endl;
	ProtoboardT pb;
	ethsnarks::mod_mixer gadget(pb, "mixer");
	gadget.generate_r1cs_constraints();
	gadget.generate_r1cs_witness(witness);

	std::cerr << "Generating key pair" << std::endl;
	auto constraints = pb.get_constraint_system();
    auto keypair = libsnark::r1cs_gg_ppzksnark_zok_generator<ppT>(constraints);

    std::cerr << "Generating proof" << std::endl;
    auto primary_input = pb.primary_input();
    auto auxiliary_input = pb.auxiliary_input();
    auto proof = libsnark::r1cs_gg_ppzksnark_zok_prover<ppT>(keypair.pk, primary_input, auxiliary_input);

    std::cerr << "Verifying in-memory proof" << std::endl;
    if( ! libsnark::r1cs_gg_ppzksnark_zok_verifier_strong_IC <ppT> (keypair.vk, primary_input, proof) ) {
    	std::cerr << "Error: test 1 failed" << std::endl;
    	return 1;
    }

	std::cerr << "Exporting keys to disk" << std::endl;
	ethsnarks::vk2json_file(keypair.vk, mixer_vk);
	ethsnarks::writeToFile<decltype(keypair.pk)>(mixer_pk, keypair.pk);

	const auto proof_json = ethsnarks::proof_to_json(proof, primary_input);
	if( argc > 2 ) {
		std::ofstream proof_json_fh(argv[3]);
		proof_json_fh << proof_json;
		proof_json_fh.close();

		if( argc > 3 ) {
			std::ofstream proof_input_fh(argv[4]);
			proof_input_fh << selftest_proof_inputs_json;
			proof_input_fh.close();
		}
	}

	std::cerr << "Verifying proof JSON, using VK from disk" << std::endl;
	const auto vk_json = ethsnarks::vk2json(keypair.vk);	
	if( ! ethsnarks::stub_verify(vk_json.c_str(), proof_json.c_str()) ) {
		std::cerr << "Error: test 2 failed" << std::endl;
    	return 2;
	}

	std::cerr << "Generating proof, using PK from disk" << std::endl;
	const auto disk_proof_json = ethsnarks::stub_prove_from_pb(pb, mixer_pk);
	if( ! ethsnarks::stub_verify(vk_json.c_str(), disk_proof_json.c_str()) ) {
		std::cerr << "Error: test 3 failed" << std::endl;
    	return 3;
	}

	return 0;
}