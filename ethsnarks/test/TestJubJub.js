// Copyright (c) 2018 @HarryR
// Copyright (c) 2018 @yondonfu
// License: LGPL-3.0+

const JubJubPublic = artifacts.require("JubJubPublic");

contract("JubJubPublic", () => {
    let curve;

    before(async () => {
        curve = await JubJubPublic.new();
    });

    describe("pointAdd", () => {
        it("doubles a point", async () => {
            let g = await curve.pointAdd.estimateGas([0, 0], [0, 0])
            console.log(g)

            let x1 = "0xF3C160E26FC96C347DD9E705EB5A3E8D661502728609FF95B3B889296901AB5";
            let y1 = "0x9979273078B5C735585107619130E62E315C5CAFE683A064F79DFED17EB14E1";
            g = await curve.pointAdd.estimateGas([x1, y1], [x1, y1]);
            console.log(g);

            let x2 = "0x274DBCE8D15179969BC0D49FA725BDDF9DE555E0BA6A693C6ADB52FC9EE7A82C";
            let y2 = "0x5CE98C61B05F47FE2EAE9A542BD99F6B2E78246231640B54595FEBFD51EB853";
            g = await curve.pointAdd.estimateGas([x1, y1], [x2, y2]);
            console.log(g);
        });
        it("etec add", async () => {
            let x1 = "0xF3C160E26FC96C347DD9E705EB5A3E8D661502728609FF95B3B889296901AB5";
            let y1 = "0x9979273078B5C735585107619130E62E315C5CAFE683A064F79DFED17EB14E1";
            let g = await curve.pointAddViaEtec.estimateGas([x1, y1], [x1, y1]);
            console.log("pointAddViaEtec gas " + g);
        });
    });

    describe("ScalarMult", () => {
        it("scalar multiply", async () => {
            let x1 = "0xdf75d8d68fcd3f3ed660ae2a44ce66d77b4b0b379e355a39de67926e6cd8f37";
            let y1 = "0x27252e695f03ce9c338f51884303d2f03fed28e28ed704428b9e944fe5f947ce";
            let s = "0xf3c160e26fc96c347dd9e705eb5a3e8d661502728609ff95b3b889296901ab5";
            let g = await curve.scalarMult.estimateGas([x1, y1], s);
            console.log("scalar multiply gas " + g);
        });
    });
});