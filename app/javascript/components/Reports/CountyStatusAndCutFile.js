import React, { useState, useEffect, Fragment } from "react";

import {
  Button,
  Label,
  Divider,
  Form,
  Breadcrumb,
  Table,
  Accordion,
  Icon,
  Grid,
  List,
  Header,
  ButtonContent,
} from "semantic-ui-react";

import "semantic-ui-css/semantic.min.css";

import Breadcrumbs from "../Shared/Breadcrumb";
import { Controller, useForm } from "react-hook-form";
import axios from "axios";

const CountyStatusAndCutFile = ({ sl_states, nri_states, projects, url }) => {
  const [project, setProject] = useState("SL");
  const [stateOptions, setStateOptions] = useState(sl_states);
  const [submitted, setSubmitted] = useState(false);

  const {
    handleSubmit,
    reset,
    setValue,
    register,
    control,
    formState: { errors },
  } = useForm();

  console.log("CountyStatusAndCutFile", {
    sl_states,
    nri_states,
    projects,
    url,
  });

  useEffect(() => {
    console.error({ project });
    if (project === "SL") {
      setStateOptions(sl_states);
    } else if (project === "NRI") {
      setStateOptions(nri_states);
    }
  }, [project]);

  const handleChange = (e, { name, value }) => {
    if (name === "project") setProject(value);
    setValue(name, value);
  };

  const onSubmit = (data) => {
    // console.log({ data, location: `/county_status_and_cut_file/${data.state_id}?project=${project}` });

    if (data.state_id && data.project) {
        window.location.href = `/county_status_and_cut_file/${data.state_id}?project=${project}`
    }
  };

  return (
    <div>
      <Breadcrumbs>
        <Breadcrumb.Section>Exports</Breadcrumb.Section>
        <Breadcrumb.Divider />
        <Breadcrumb.Section active>
          County Status and Cut File
        </Breadcrumb.Section>
      </Breadcrumbs>
      <Divider />

      <Form>
        <Form.Group widths="equal">
          <Controller
            name={"project"}
            control={control}
            rules={{ required: "Required" }}
            defaultValue={project}
            render={({ field: { name, value, defaultValue } }) => (
              <Form.Select
                fluid
                search
                selection
                name={name}
                data-value={value}
                label={"Project"}
                required={true}
                value={value || ""}
                defaultValue={defaultValue}
                onChange={handleChange}
                autoComplete="off"
                options={projects.map((record) => {
                  return {
                    key: record,
                    text: record,
                    value: record,
                  };
                })}
                error={
                  errors["project"]
                    ? {
                        content: errors["project"].message,
                        pointing: "above",
                      }
                    : false
                }
              />
            )}
          />
          <Controller
            name={"state_id"}
            control={control}
            rules={{ required: "Required" }}
            render={({ field: { name, value } }) => (
              <Form.Select
                fluid
                search
                selection
                name={name}
                required={true}
                data-value={value}
                label={"State"}
                value={value || ""}
                onChange={handleChange}
                autoComplete="off"
                options={stateOptions.map((record) => {
                  return {
                    key: record.id,
                    text: record.name,
                    value: record.id,
                  };
                })}
                error={
                  errors["utm"]
                    ? {
                        content: errors["utm"].message,
                        pointing: "above",
                      }
                    : false
                }
              />
            )}
          />
        </Form.Group>

        <Divider />

        <Button
          primary
          animated
          floated="right"
          type="button"
          loading={submitted}
          disabled={submitted}
          onClick={handleSubmit(onSubmit)}
        >
          <ButtonContent visible>Submit</ButtonContent>
          <ButtonContent hidden>
            <Icon name="arrow right" />
          </ButtonContent>
        </Button>
        
        <div style={{ clear: "both" }} />
        <br />
        <br />
        <br />
      </Form>
    </div>
  );
};

export default CountyStatusAndCutFile;
